defmodule MobilizonWeb.Resolvers.Actor do
  alias Mobilizon.Actors.Actor, as: ActorSchema
  alias Mobilizon.Actors.User
  alias Mobilizon.Actors
  alias Mobilizon.Service.ActivityPub

  def find_actor(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPub.find_or_make_actor_from_nickname(name) do
      {:ok, actor} ->
        {:ok, actor}
      _ ->
        {:error, "Actor with name #{name} not found"}
    end
  end

  @doc """
  Returns the current actor for the currently logged-in user
  """
  def get_current_actor(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Actors.get_actor_for_user(user)}
  end

  def get_current_actor(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view current actor"}
  end
end
