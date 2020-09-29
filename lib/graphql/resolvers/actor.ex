defmodule Mobilizon.GraphQL.Resolvers.Actor do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Admin, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Refresher
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  require Logger

  def refresh_profile(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Actors.get_actor(id) do
      %Actor{domain: domain} = actor when not is_nil(domain) ->
        Refresher.refresh_profile(actor)
        {:ok, actor}

      %Actor{} ->
        {:error, dgettext("errors", "Only remote profiles may be refreshed")}

      _ ->
        {:error, dgettext("errors", "No profile found with this ID")}
    end
  end

  def suspend_profile(_parent, %{id: id}, %{
        context: %{current_user: %User{role: role} = user}
      })
      when is_moderator(role) do
    with {:moderator_actor, %Actor{} = moderator_actor} <-
           {:moderator_actor, Users.get_actor_for_user(user)},
         %Actor{suspended: false} = actor <- Actors.get_actor_with_preload(id) do
      case actor do
        # Suspend a group on this instance
        %Actor{type: :Group, domain: nil} ->
          Logger.debug("We're suspending a group on this very instance")
          ActivityPub.delete(actor, moderator_actor, true, %{suspension: true})
          Admin.log_action(moderator_actor, "suspend", actor)
          {:ok, actor}

        # Delete a remote actor
        %Actor{domain: domain} when not is_nil(domain) ->
          Logger.debug("We're just deleting a remote instance")
          Actors.delete_actor(actor, suspension: true)
          Admin.log_action(moderator_actor, "suspend", actor)
          {:ok, actor}

        %Actor{domain: nil} ->
          {:error, dgettext("errors", "No remote profile found with this ID")}
      end
    else
      {:moderator_actor, nil} ->
        {:error, dgettext("errors", "No profile found for the moderator user")}

      %Actor{suspended: true} ->
        {:error, dgettext("errors", "Profile already suspended")}

      {:error, _} ->
        {:error, dgettext("errors", "Error while performing background task")}
    end
  end

  def suspend_profile(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can suspend a profile")}
  end

  def unsuspend_profile(_parent, %{id: id}, %{
        context: %{current_user: %User{role: role} = user}
      })
      when is_moderator(role) do
    with {:moderator_actor, %Actor{} = moderator_actor} <-
           {:moderator_actor, Users.get_actor_for_user(user)},
         %Actor{suspended: true} = actor <-
           Actors.get_actor_with_preload(id, true),
         {:delete_tombstones, {_, nil}} <-
           {:delete_tombstones, Mobilizon.Tombstone.delete_actor_tombstones(id)},
         {:ok, %Actor{} = actor} <- Actors.update_actor(actor, %{suspended: false}),
         {:ok, %Actor{} = actor} <- refresh_if_remote(actor),
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

  @spec refresh_if_remote(Actor.t()) :: {:ok, Actor.t()}
  defp refresh_if_remote(%Actor{domain: nil} = actor), do: {:ok, actor}
  defp refresh_if_remote(%Actor{} = actor), do: Refresher.refresh_profile(actor)
end
