defmodule Mobilizon.GraphQL.Resolvers.Actor do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Admin}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Service.Workers.Background
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  require Logger

  @spec refresh_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def refresh_profile(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Actors.get_actor(id) do
      %Actor{domain: domain, id: actor_id} = actor when not is_nil(domain) ->
        Background.enqueue("refresh_profile", %{
          "actor_id" => actor_id
        })

        {:ok, actor}

      %Actor{} ->
        {:error, dgettext("errors", "Only remote profiles may be refreshed")}

      _ ->
        {:error, dgettext("errors", "No profile found with this ID")}
    end
  end

  @spec suspend_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def suspend_profile(_parent, %{id: id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    case Actors.get_actor_with_preload(id) do
      # Suspend a group on this instance
      %Actor{suspended: false, type: :Group, domain: nil} = actor ->
        Logger.debug("We're suspending a group on this very instance")
        Actions.Delete.delete(actor, moderator_actor, true, %{suspension: true})
        Admin.log_action(moderator_actor, "suspend", actor)
        {:ok, actor}

      # Delete a remote actor
      %Actor{suspended: false, domain: domain} = actor when not is_nil(domain) ->
        Logger.debug("We're just deleting a remote instance")
        Actors.delete_actor(actor, suspension: true)
        Admin.log_action(moderator_actor, "suspend", actor)
        {:ok, actor}

      %Actor{suspended: false, domain: nil} ->
        {:error, dgettext("errors", "No remote profile found with this ID")}

      %Actor{suspended: true} ->
        {:error, dgettext("errors", "Profile already suspended")}

      nil ->
        {:error, dgettext("errors", "Profile not found")}
    end
  end

  def suspend_profile(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can suspend a profile")}
  end

  @spec unsuspend_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def unsuspend_profile(_parent, %{id: id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    with %Actor{suspended: true} = actor <-
           Actors.get_actor_with_preload(id, true),
         {:delete_tombstones, {_, nil}} <-
           {:delete_tombstones, Mobilizon.Tombstone.delete_actor_tombstones(id)},
         {:ok, %Actor{} = actor} <- Actors.update_actor(actor, %{suspended: false}),
         :ok <- refresh_if_remote(actor),
         {:ok, _} <- Admin.log_action(moderator_actor, "unsuspend", actor) do
      {:ok, actor}
    else
      {:moderator_actor, nil} ->
        {:error, dgettext("errors", "No profile found for the moderator user")}

      nil ->
        {:error, dgettext("errors", "No remote profile found with this ID")}

      {:error, _} ->
        {:error, dgettext("errors", "Error while performing background task")}
    end
  end

  def unsuspend_profile(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can unsuspend a profile")}
  end

  @spec refresh_if_remote(Actor.t()) :: :ok
  defp refresh_if_remote(%Actor{domain: nil}), do: :ok

  defp refresh_if_remote(%Actor{id: actor_id}) do
    Background.enqueue("refresh_profile", %{
      "actor_id" => actor_id
    })

    :ok
  end
end
