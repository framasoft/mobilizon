defmodule Mobilizon.GraphQL.API.Groups do
  @moduledoc """
  API for Groups.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Service.Formatter.HTML

  @doc """
  Create a group
  """
  @spec create_group(map) :: {:ok, Activity.t(), Actor.t()} | any
  def create_group(args) do
    with preferred_username <-
           args |> Map.get(:preferred_username) |> HTML.strip_tags() |> String.trim(),
         {:existing_group, nil} <-
           {:existing_group, Actors.get_local_actor_by_name(preferred_username)},
         args <- args |> Map.put(:type, :Group),
         {:ok, %Activity{} = activity, %Actor{} = group} <-
           ActivityPub.create(:actor, args, true, %{"actor" => args.creator_actor.url}) do
      {:ok, activity, group}
    else
      {:existing_group, _} ->
        {:error, "A group with this name already exists"}
    end
  end

  @spec create_group(map) :: {:ok, Activity.t(), Actor.t()} | any
  def update_group(%{id: id} = args) do
    with {:existing_group, {:ok, %Actor{type: :Group} = group}} <-
           {:existing_group, Actors.get_group_by_actor_id(id)},
         {:ok, %Activity{} = activity, %Actor{} = group} <-
           ActivityPub.update(group, args, true, %{"actor" => args.updater_actor.url}) do
      {:ok, activity, group}
    else
      {:existing_group, _} ->
        {:error, "A group with this name already exists"}
    end
  end
end
