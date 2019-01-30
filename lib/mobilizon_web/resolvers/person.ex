defmodule MobilizonWeb.Resolvers.Person do
  @moduledoc """
  Handles the person-related GraphQL calls
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, User}
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

  @doc """
  This function is used to create more identities from an existing user
  """
  def create_person(_parent, %{preferred_username: _preferred_username} = args, %{
        context: %{current_user: user}
      }) do
    args = Map.put(args, :user_id, user.id)

    with {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    end
  end

  @doc """
  This function is used to register a person afterwards the user has been created (but not activated)
  """
  def register_person(_parent, args, _resolution) do
    with {:ok, %User{} = user} <- Actors.get_user_by_email(args.email),
         {:no_actor, nil} <- {:no_actor, Actors.get_actor_for_user(user)},
         args <- Map.put(args, :user_id, user.id),
         {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    else
      {:error, :user_not_found} ->
        {:error, "User with email not found"}

      {:no_actor, _} ->
        {:error, "You already have a profile for this user"}

      {:error, %Ecto.Changeset{} = e} ->
        {:error, e}
    end
  end
end
