defmodule MobilizonWeb.Resolvers.Actor do
  alias Mobilizon.Actors.Actor, as: ActorSchema
  alias Mobilizon.Actors.User
  alias Mobilizon.Actors

  def find_actor(_parent, %{preferred_username: name}, _resolution) do
    case Actors.get_actor_by_name_with_everything(name) do
      nil ->
        {:error, "Actor with name #{name} not found"}

      actor ->
        {:ok, actor}
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
