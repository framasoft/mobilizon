defmodule MobilizonWeb.Resolvers.Group do
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor}
  alias Mobilizon.Service.ActivityPub
  require Logger

  @doc """
  Find a group
  """
  def find_group(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPub.find_or_make_group_from_nickname(name) do
      {:ok, actor} ->
        {:ok, actor}

      _ ->
        {:error, "Group with name #{name} not found"}
    end
  end

  @doc """
  Lists all groups
  """
  def list_groups(_parent, _args, _resolution) do
    {:ok, Actors.list_groups}
  end

  @doc """
  Create a new group. The creator is automatically added as admin
  """
  def create_group(
        _parent,
        %{preferred_username: preferred_username, creator_username: actor_username},
        %{
          context: %{current_user: user}
        }
      ) do

    with %Actor{id: actor_id} <- Actors.get_local_actor_by_name(actor_username),
         {:user_actor, true} <-
           {:user_actor, actor_id in Enum.map(Actors.get_actors_for_user(user), & &1.id)},
        {:ok, %Actor{} = group} <- Actors.create_group(%{preferred_username: preferred_username}) do
          {:ok, group}
    else
      {:error, %Ecto.Changeset{errors: [url: {"has already been taken", []}]}} ->
        {:error, :group_name_not_available}
      err ->
        Logger.error(inspect(err))
        err
    end
  end

  def create_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create a group"}
  end
end
