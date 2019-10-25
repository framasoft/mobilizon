defmodule MobilizonWeb.Resolvers.Person do
  @moduledoc """
  Handles the person-related GraphQL calls
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Participant
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @doc """
  Get a person
  """
  def get_person(_parent, %{id: id}, _resolution) do
    with %Actor{} = actor <- Actors.get_actor_with_preload(id),
         actor <- proxify_pictures(actor) do
      {:ok, actor}
    else
      _ ->
        {:error, "Person with ID #{id} not found"}
    end
  end

  @doc """
  Find a person
  """
  def fetch_person(_parent, %{preferred_username: preferred_username}, _resolution) do
    with {:ok, %Actor{} = actor} <-
           ActivityPub.find_or_make_actor_from_nickname(preferred_username),
         actor <- proxify_pictures(actor) do
      {:ok, actor}
    else
      _ ->
        {:error, "Person with username #{preferred_username} not found"}
    end
  end

  @doc """
  Returns the current actor for the currently logged-in user
  """
  def get_current_person(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Users.get_actor_for_user(user)}
  end

  def get_current_person(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view current person"}
  end

  @doc """
  Returns the list of identities for the logged-in user
  """
  def identities(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Users.get_actors_for_user(user)}
  end

  def identities(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view your list of identities"}
  end

  @doc """
  This function is used to create more identities from an existing user
  """
  def create_person(
        _parent,
        %{preferred_username: _preferred_username} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    args = Map.put(args, :user_id, user.id)

    with args <- save_attached_pictures(args),
         {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    end
  end

  @doc """
  This function is used to create more identities from an existing user
  """
  def create_person(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create a new identity"}
  end

  @doc """
  This function is used to update an existing identity
  """
  def update_person(
        _parent,
        %{id: id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    args = Map.put(args, :user_id, user.id)

    with {:find_actor, %Actor{} = actor} <-
           {:find_actor, Actors.get_actor(id)},
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor.id),
         args <- save_attached_pictures(args),
         {:ok, actor} <- Actors.update_actor(actor, args) do
      {:ok, actor}
    else
      {:find_actor, nil} ->
        {:error, "Actor not found"}

      {:is_owned, nil} ->
        {:error, "Actor is not owned by authenticated user"}
    end
  end

  def update_person(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to update an identity"}
  end

  @doc """
  This function is used to delete an existing identity
  """
  def delete_person(
        _parent,
        %{id: id} = _args,
        %{context: %{current_user: user}} = _resolution
      ) do
    with {:find_actor, %Actor{} = actor} <-
           {:find_actor, Actors.get_actor(id)},
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor.id),
         {:last_identity, false} <- {:last_identity, last_identity?(user)},
         {:last_admin, false} <- {:last_admin, last_admin_of_a_group?(actor.id)},
         {:ok, actor} <- Actors.delete_actor(actor) do
      {:ok, actor}
    else
      {:find_actor, nil} ->
        {:error, "Actor not found"}

      {:last_identity, true} ->
        {:error, "Cannot remove the last identity of a user"}

      {:last_admin, true} ->
        {:error, "Cannot remove the last administrator of a group"}

      {:is_owned, nil} ->
        {:error, "Actor is not owned by authenticated user"}
    end
  end

  def delete_person(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete an identity"}
  end

  defp last_identity?(user) do
    length(Users.get_actors_for_user(user)) <= 1
  end

  defp save_attached_pictures(args) do
    Enum.reduce([:avatar, :banner], args, fn key, args ->
      if Map.has_key?(args, key) && !is_nil(args[key][:picture]) do
        pic = args[key][:picture]

        with {:ok, %{name: name, url: url, content_type: content_type, size: _size}} <-
               MobilizonWeb.Upload.store(pic.file, type: key, description: pic.alt) do
          Map.put(args, key, %{"name" => name, "url" => url, "mediaType" => content_type})
        end
      else
        args
      end
    end)
  end

  @doc """
  This function is used to register a person afterwards the user has been created (but not activated)
  """
  def register_person(_parent, args, _resolution) do
    with {:ok, %User{} = user} <- Users.get_user_by_email(args.email),
         {:no_actor, nil} <- {:no_actor, Users.get_actor_for_user(user)},
         args <- Map.put(args, :user_id, user.id),
         args <- save_attached_pictures(args),
         {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    else
      {:error, :user_not_found} ->
        {:error, "No user with this email was found"}

      {:no_actor, _} ->
        {:error, "You already have a profile for this user"}

      {:error, %Ecto.Changeset{} = e} ->
        {:error, e}
    end
  end

  @doc """
  Returns the participation for a specific event
  """
  def person_participations(%Actor{id: actor_id}, %{event_id: event_id}, %{
        context: %{current_user: user}
      }) do
    with {:is_owned, %Actor{} = _actor} <- User.owns_actor(user, actor_id),
         {:no_participant, {:ok, %Participant{} = participant}} <-
           {:no_participant, Events.get_participant(event_id, actor_id)} do
      {:ok, [participant]}
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:no_participant, _} ->
        {:ok, []}
    end
  end

  @doc """
  Returns the list of events this person is going to
  """
  def person_participations(%Actor{id: actor_id}, _args, %{context: %{current_user: user}}) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         participations <- Events.list_event_participations_for_actor(actor) do
      {:ok, participations}
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end

  def proxify_pictures(%Actor{} = actor) do
    actor
    |> proxify_avatar
    |> proxify_banner
  end

  # We check that the actor is not the last administrator/creator of a group
  @spec last_admin_of_a_group?(integer()) :: boolean()
  defp last_admin_of_a_group?(actor_id) do
    length(Actors.list_group_ids_where_last_administrator(actor_id)) > 0
  end

  @spec proxify_avatar(Actor.t()) :: Actor.t()
  defp proxify_avatar(%Actor{avatar: %{url: avatar_url} = avatar} = actor) do
    actor |> Map.put(:avatar, avatar |> Map.put(:url, MobilizonWeb.MediaProxy.url(avatar_url)))
  end

  @spec proxify_avatar(Actor.t()) :: Actor.t()
  defp proxify_avatar(%Actor{} = actor), do: actor

  @spec proxify_banner(Actor.t()) :: Actor.t()
  defp proxify_banner(%Actor{banner: %{url: banner_url} = banner} = actor) do
    actor |> Map.put(:banner, banner |> Map.put(:url, MobilizonWeb.MediaProxy.url(banner_url)))
  end

  @spec proxify_banner(Actor.t()) :: Actor.t()
  defp proxify_banner(%Actor{} = actor), do: actor
end
