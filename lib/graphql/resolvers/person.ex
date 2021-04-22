defmodule Mobilizon.GraphQL.Resolvers.Person do
  @moduledoc """
  Handles the person-related GraphQL calls
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.Participant
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  require Logger

  alias Mobilizon.Web.Upload

  @doc """
  Get a person
  """
  def get_person(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}}) do
    with %Actor{suspended: suspended} = actor <- Actors.get_actor_with_preload(id, true),
         true <- suspended == false or is_moderator(role) do
      {:ok, actor}
    else
      _ ->
        {:error, dgettext("errors", "Person with ID %{id} not found", id: id)}
    end
  end

  def get_person(_parent, _args, _resolution), do: {:error, :unauthorized}

  @doc """
  Find a person
  """
  def fetch_person(_parent, %{preferred_username: preferred_username}, %{
        context: %{current_user: %User{} = user}
      }) do
    with {:ok, %Actor{id: actor_id} = actor} <-
           ActivityPubActor.find_or_make_actor_from_nickname(preferred_username),
         {:own, {:is_owned, _}} <- {:own, User.owns_actor(user, actor_id)} do
      {:ok, actor}
    else
      {:own, nil} ->
        {:error, :unauthorized}

      _ ->
        {:error,
         dgettext("errors", "Person with username %{username} not found",
           username: preferred_username
         )}
    end
  end

  def fetch_person(_parent, _args, _resolution), do: {:error, :unauthenticated}

  def list_persons(
        _parent,
        %{
          preferred_username: preferred_username,
          name: name,
          domain: domain,
          local: local,
          suspended: suspended,
          page: page,
          limit: limit
        },
        %{
          context: %{current_user: %User{role: role}}
        }
      )
      when is_moderator(role) do
    {:ok,
     Actors.list_actors(:Person, preferred_username, name, domain, local, suspended, page, limit)}
  end

  def list_persons(_parent, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when not is_moderator(role) do
    {:error, :unauthorized}
  end

  def list_persons(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  Returns the current actor for the currently logged-in user
  """
  def get_current_person(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Users.get_actor_for_user(user)}
  end

  def get_current_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  Returns the list of identities for the logged-in user
  """
  def identities(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Users.get_actors_for_user(user)}
  end

  def identities(_parent, _args, _resolution) do
    {:error, :unauthenticated}
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

    with args <- Map.update(args, :preferred_username, "", &String.downcase/1),
         {:picture, args} when is_map(args) <- {:picture, save_attached_pictures(args)},
         {:ok, %Actor{} = new_person} <- Actors.new_person(args) do
      {:ok, new_person}
    else
      {:error, err} ->
        {:error, err}

      {:picture, {:error, :file_too_large}} ->
        {:error, dgettext("errors", "The provided picture is too heavy")}
    end
  end

  def create_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  This function is used to update an existing identity
  """
  def update_person(
        _parent,
        %{id: id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    require Logger
    args = Map.put(args, :user_id, user.id)

    with {:find_actor, %Actor{} = actor} <-
           {:find_actor, Actors.get_actor(id)},
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor.id),
         {:picture, args} when is_map(args) <- {:picture, save_attached_pictures(args)},
         {:ok, _activity, %Actor{} = actor} <- ActivityPub.update(actor, args, true) do
      {:ok, actor}
    else
      {:picture, {:error, :file_too_large}} ->
        {:error, dgettext("errors", "The provided picture is too heavy")}

      {:find_actor, nil} ->
        {:error, dgettext("errors", "Profile not found")}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def update_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
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
        {:error, dgettext("errors", "Profile not found")}

      {:last_identity, true} ->
        {:error, dgettext("errors", "Cannot remove the last identity of a user")}

      {:last_admin, true} ->
        {:error, dgettext("errors", "Cannot remove the last administrator of a group")}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def delete_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  defp last_identity?(user) do
    length(Users.get_actors_for_user(user)) <= 1
  end

  defp save_attached_pictures(args) do
    with args when is_map(args) <- save_attached_picture(args, :avatar),
         args when is_map(args) <- save_attached_picture(args, :banner) do
      args
    end
  end

  defp save_attached_picture(args, key) do
    if Map.has_key?(args, key) && !is_nil(args[key][:media]) do
      with media when is_map(media) <- save_picture(args[key][:media], key) do
        Map.put(args, key, media)
      end
    else
      args
    end
  end

  defp save_picture(media, key) do
    with {:ok, %{name: name, url: url, content_type: content_type, size: size}} <-
           Upload.store(media.file, type: key, description: media.alt) do
      %{"name" => name, "url" => url, "content_type" => content_type, "size" => size}
    end
  end

  @doc """
  This function is used to register a person afterwards the user has been created (but not activated)
  """
  def register_person(_parent, args, _resolution) do
    # When registering, email is assumed confirmed (unlike changing email)
    with {:ok, %User{} = user} <- Users.get_user_by_email(args.email, unconfirmed: false),
         user_actor <- Users.get_actor_for_user(user),
         no_actor <- is_nil(user_actor),
         {:no_actor, true} <- {:no_actor, no_actor},
         args <- Map.update(args, :preferred_username, "", &String.downcase/1),
         args <- Map.put(args, :user_id, user.id),
         {:picture, args} when is_map(args) <- {:picture, save_attached_pictures(args)},
         {:ok, %Actor{} = new_person} <- Actors.new_person(args, true) do
      {:ok, new_person}
    else
      {:picture, {:error, :file_too_large}} ->
        {:error, dgettext("errors", "The provided picture is too heavy")}

      {:error, :user_not_found} ->
        {:error, dgettext("errors", "No user with this email was found")}

      {:no_actor, _} ->
        {:error, dgettext("errors", "You already have a profile for this user")}

      {:error, %Ecto.Changeset{} = e} ->
        {:error, e}
    end
  end

  @doc """
  Returns the participations, optionally restricted to an event
  """
  def person_participations(
        %Actor{id: actor_id},
        %{event_id: event_id},
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{} = _actor} <- User.owns_actor(user, actor_id),
         {:no_participant, {:ok, %Participant{} = participant}} <-
           {:no_participant, Events.get_participant(event_id, actor_id)} do
      {:ok, %Page{elements: [participant], total: 1}}
    else
      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}

      {:no_participant, _} ->
        {:ok, %Page{elements: [], total: 0}}
    end
  end

  def person_participations(%Actor{id: actor_id} = actor, %{page: page, limit: limit}, %{
        context: %{current_user: %User{role: role} = user}
      }) do
    {:is_owned, actor_found} = User.owns_actor(user, actor_id)

    res =
      cond do
        not is_nil(actor_found) ->
          true

        is_moderator(role) ->
          true

        true ->
          false
      end

    with {:is_owned, true} <- {:is_owned, res},
         %Page{} = page <- Events.list_event_participations_for_actor(actor, page, limit) do
      {:ok, page}
    else
      {:is_owned, false} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @doc """
  Returns the list of events this person is going to
  """
  @spec person_memberships(Actor.t(), map(), map()) :: {:ok, Page.t()} | {:error, String.t()}
  def person_memberships(%Actor{id: actor_id}, %{group: group}, %{
        context: %{current_user: user}
      }) do
    with {:is_owned, %Actor{id: actor_id}} <- User.owns_actor(user, actor_id),
         {:group, %Actor{id: group_id}} <- {:group, Actors.get_actor_by_name(group, :Group)},
         {:ok, %Member{} = membership} <- Actors.get_member(actor_id, group_id),
         memberships <- %Page{
           total: 1,
           elements: [Repo.preload(membership, [:actor, :parent, :invited_by])]
         } do
      {:ok, memberships}
    else
      {:error, :member_not_found} ->
        {:ok, %Page{total: 0, elements: []}}

      {:group, nil} ->
        {:error, :group_not_found}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def person_memberships(%Actor{id: actor_id}, %{page: page, limit: limit}, %{
        context: %{current_user: user}
      }) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         memberships <- Actors.list_members_for_actor(actor, page, limit) do
      {:ok, memberships}
    else
      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def user_for_person(%Actor{type: :Person, user_id: user_id}, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    with false <- is_nil(user_id),
         %User{} = user <- Users.get_user(user_id) do
      {:ok, user}
    else
      true ->
        {:ok, nil}

      _ ->
        {:error, dgettext("errors", "User not found")}
    end
  end

  def user_for_person(_, _args, _resolution), do: {:error, nil}

  def organized_events_for_person(
        %Actor{user_id: actor_user_id} = actor,
        %{page: page, limit: limit},
        %{
          context: %{current_user: %User{id: user_id, role: role}}
        }
      ) do
    with {:can_get_events, true} <-
           {:can_get_events, actor_user_id == user_id or is_moderator(role)},
         %Page{} = page <- Events.list_organized_events_for_actor(actor, page, limit) do
      {:ok, page}
    else
      {:can_get_events, false} ->
        {:error, :unauthorized}
    end
  end

  def organized_events_for_person(_parent, _args, _resolution),
    do: {:ok, %Page{elements: [], total: 0}}

  # We check that the actor is not the last administrator/creator of a group
  @spec last_admin_of_a_group?(integer()) :: boolean()
  defp last_admin_of_a_group?(actor_id) do
    length(Actors.list_group_ids_where_last_administrator(actor_id)) > 0
  end
end
