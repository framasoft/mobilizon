defmodule MobilizonWeb.Resolvers.Person do
  @moduledoc """
  Handles the person-related GraphQL calls
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub

  @deprecated "Use find_person/3 or find_group/3 instead"
  def find_actor(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPub.find_or_make_actor_from_nickname(name) do
      {:ok, actor} ->
        {:ok, actor}

      _ ->
        {:error, "Actor with name #{name} not found"}
    end
  end

  @doc """
  Find a person
  """
  def find_person(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPub.find_or_make_person_from_nickname(name) do
      {:ok, actor} ->
        {:ok, actor}

      _ ->
        {:error, "Person with name #{name} not found"}
    end
  end

  @doc """
  Returns the current actor for the currently logged-in user
  """
  def get_current_person(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Actors.get_actor_for_user(user)}
  end

  def get_current_person(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view current person"}
  end

  @doc """
  Returns the list of identities for the logged-in user
  """
  def identities(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Actors.get_actors_for_user(user)}
  end

  def identities(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view your list of identities"}
  end

  def create_person(_parent, %{preferred_username: _preferred_username} = args, %{
        context: %{current_user: user}
      }) do
    args = Map.put(args, :user_id, user.id)

    with {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    else
      {:error, %Ecto.Changeset{} = _e} ->
        {:error, "Unable to create a profile with this username"}
    end
  end
end
