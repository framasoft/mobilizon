defmodule Mobilizon.GraphQL.Resolvers.Person do
  @moduledoc """
  Handles the person-related GraphQL calls
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.Participant
  alias Mobilizon.Service.AntiSpam
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  require Logger

  alias Mobilizon.Web.Upload

  @doc """
  Get a person
  """
  @spec get_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t() | :unauthorized}
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
  @spec fetch_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t() | :unauthorized | :unauthenticated}
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

  @spec list_persons(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Actor.t())} | {:error, :unauthorized | :unauthenticated}
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
  @spec get_current_person(any, any, Absinthe.Resolution.t()) ::
          {:error, :unauthenticated | :no_current_person} | {:ok, Actor.t()}
  def get_current_person(_parent, _args, %{context: %{current_actor: %Actor{} = actor}}) do
    {:ok, actor}
  end

  def get_current_person(_parent, _args, %{context: %{current_user: %User{}}}) do
    {:error, :no_current_person}
  end

  def get_current_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  Returns the list of identities for the logged-in user
  """
  @spec identities(any, any, Absinthe.Resolution.t()) ::
          {:error, :unauthenticated} | {:ok, list(Actor.t())}
  def identities(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Users.get_actors_for_user(user)}
  end

  def identities(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  This function is used to create more identities from an existing user
  """
  @spec create_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t() | :unauthenticated}
  def create_person(
        _parent,
        %{preferred_username: _preferred_username} = args,
        %{context: %{current_user: user} = context} = _resolution
      ) do
    args = Map.put(args, :user_id, user.id)
    user_agent = Map.get(context, :user_agent, "")

    with args <- Map.update(args, :preferred_username, "", &String.downcase/1),
         {:spam, :ham} <-
           {:spam,
            AntiSpam.service().check_profile(
              args.preferred_username,
              args.summary,
              user.email,
              user.current_sign_in_ip,
              user_agent
            )},
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
  @spec update_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t() | :unauthenticated}
  def update_person(
        _parent,
        %{id: id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    require Logger
    args = Map.put(args, :user_id, user.id)

    case owned_actor(user, id) do
      {:ok, %Actor{} = actor} ->
        case save_attached_pictures(args) do
          args when is_map(args) ->
            case Actions.Update.update(actor, args, true) do
              {:ok, _activity, %Actor{} = actor} ->
                {:ok, actor}

              {:error, err} ->
                {:error, err}
            end

          {:error, :file_too_large} ->
            {:error, dgettext("errors", "The provided picture is too heavy")}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  def update_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  This function is used to delete an existing identity
  """
  @spec delete_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t() | :unauthenticated}
  def delete_person(
        _parent,
        %{id: id} = _args,
        %{context: %{current_user: %User{} = user}} = _resolution
      ) do
    case owned_actor(user, id) do
      {:ok, %Actor{} = actor} ->
        if last_identity?(user) do
          {:error, dgettext("errors", "Cannot remove the last identity of a user")}
        else
          if last_admin_of_a_group?(actor.id) do
            {:error, dgettext("errors", "Cannot remove the last administrator of a group")}
          else
            Actors.delete_actor(actor)
          end
        end

      {:error, err} ->
        {:error, err}
    end
  end

  def delete_person(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @spec owned_actor(User.t(), integer() | String.t()) :: {:error, String.t()} | {:ok, Actor.t()}
  defp owned_actor(%User{} = user, actor_id) do
    with {:find_actor, %Actor{} = actor} <-
           {:find_actor, Actors.get_actor(actor_id)},
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor.id) do
      {:ok, actor}
    else
      {:find_actor, nil} ->
        {:error, dgettext("errors", "Profile not found")}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @spec last_identity?(User.t()) :: boolean
  defp last_identity?(user) do
    length(Users.get_actors_for_user(user)) <= 1
  end

  @spec save_attached_pictures(map()) :: map() | {:error, any()}
  defp save_attached_pictures(args) do
    case save_attached_picture(args, :avatar) do
      {:error, err} ->
        {:error, err}

      args when is_map(args) ->
        case save_attached_picture(args, :banner) do
          {:error, err} ->
            {:error, err}

          args when is_map(args) ->
            args
        end
    end
  end

  @spec save_attached_picture(map(), :avatar | :banner) :: map() | {:error, any}
  defp save_attached_picture(args, key) do
    if Map.has_key?(args, key) && !is_nil(args[key][:media]) do
      case save_picture(args[key][:media], key) do
        {:error, err} ->
          {:error, err}

        media when is_map(media) ->
          Map.put(args, key, media)
      end
    else
      args
    end
  end

  @spec save_picture(map(), :avatar | :banner) :: {:ok, map()} | {:error, any()}
  defp save_picture(media, key) do
    case Upload.store(media.file, type: key, description: media.alt) do
      {:ok, %{name: name, url: url, content_type: content_type, size: size}} ->
        %{"name" => name, "url" => url, "content_type" => content_type, "size" => size}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  This function is used to register a person afterwards the user has been created (but not activated)
  """
  @spec register_person(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def register_person(_parent, args, %{context: context}) do
    current_ip = Map.get(context, :ip)
    user_agent = Map.get(context, :user_agent, "")

    # When registering, email is assumed confirmed (unlike changing email)
    case Users.get_user_by_email(args.email, unconfirmed: false) do
      {:ok, %User{} = user} ->
        if is_nil(Users.get_actor_for_user(user)) do
          # No profile yet, we can create one
          with {:spam, :ham} <-
                 {:spam,
                  AntiSpam.service().check_profile(
                    args.preferred_username,
                    args.summary,
                    args.email,
                    current_ip,
                    user_agent
                  )},
               args when is_map(args) <- prepare_args(args, user) do
            Actors.new_person(args, true)
          else
            {:error, :file_too_large} ->
              {:error, dgettext("errors", "The provided picture is too heavy")}

            {:error, _err} ->
              {:error, dgettext("errors", "Error while uploading pictures")}

            {:spam, _} ->
              {:error, dgettext("errors", "Your profile was detected as spam.")}
          end
        else
          {:error, dgettext("errors", "You already have a profile for this user")}
        end

      {:error, :user_not_found} ->
        {:error, dgettext("errors", "No user with this email was found")}
    end
  end

  @spec prepare_args(map(), User.t()) :: map() | {:error, any()}
  defp prepare_args(args, %User{} = user) do
    args
    |> Map.update(:preferred_username, "", &String.downcase/1)
    |> Map.put(:user_id, user.id)
    |> save_attached_pictures()
  end

  @doc """
  Returns the participations, optionally restricted to an event
  """
  @spec person_participations(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Participant.t())} | {:error, :unauthorized | String.t()}
  def person_participations(
        %Actor{id: actor_id} = person,
        %{event_id: event_id},
        %{context: %{current_user: %User{} = user}}
      ) do
    if user_can_access_person_details?(person, user) do
      case Events.get_participant(event_id, actor_id) do
        {:ok, %Participant{} = participant} -> {:ok, %Page{elements: [participant], total: 1}}
        {:error, :participant_not_found} -> {:ok, %Page{elements: [], total: 0}}
      end
    else
      {:error, :unauthorized}
    end
  end

  def person_participations(%Actor{} = person, %{page: page, limit: limit}, %{
        context: %{current_user: %User{} = user}
      }) do
    if user_can_access_person_details?(person, user) do
      %Page{} = page = Events.list_event_participations_for_actor(person, page, limit)
      {:ok, page}
    else
      {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @doc """
  Returns this person's group memberships
  """
  @spec person_memberships(Actor.t(), map(), map()) ::
          {:ok, Page.t(Member.t())} | {:error, String.t()}
  def person_memberships(%Actor{id: actor_id} = person, args, %{
        context: %{current_user: %User{} = user}
      }) do
    if user_can_access_person_details?(person, user) do
      with {:group, %Actor{id: group_id}} <- {:group, group_from_args(args)},
           {:ok, %Member{} = membership} <- Actors.get_member(actor_id, group_id) do
        {:ok,
         %Page{
           total: 1,
           elements: [Repo.preload(membership, [:actor, :parent, :invited_by])]
         }}
      else
        {:error, :member_not_found} ->
          {:ok, %Page{total: 0, elements: []}}

        {:group, :none} ->
          with {:can_get_memberships, true} <-
                 {:can_get_memberships, user_can_access_person_details?(person, user)},
               memberships <-
                 Actors.list_members_for_actor(
                   person,
                   Map.get(args, :page, 1),
                   Map.get(args, :limit, 10)
                 ) do
            {:ok, memberships}
          else
            {:can_get_memberships, _} ->
              {:error, dgettext("errors", "Profile is not owned by authenticated user")}
          end

        {:group, nil} ->
          {:error, :group_not_found}
      end
    else
      {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @doc """
  Returns this person's group follows
  """
  @spec person_follows(Actor.t(), map(), map()) ::
          {:ok, Page.t(Follower.t())} | {:error, String.t()}
  def person_follows(%Actor{} = person, %{group: group}, %{
        context: %{current_user: %User{} = user}
      }) do
    if user_can_access_person_details?(person, user) do
      with {:group, %Actor{} = group} <- {:group, Actors.get_actor_by_name(group, :Group)},
           %Follower{} = follow <-
             Actors.get_follower_by_followed_and_following(group, person) do
        {:ok,
         %Page{
           total: 1,
           elements: [follow]
         }}
      else
        nil ->
          {:ok, %Page{total: 0, elements: []}}

        {:group, nil} ->
          {:error, :group_not_found}
      end
    else
      {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def person_follows(
        %Actor{} = person,
        %{page: page, limit: limit},
        %{
          context: %{current_user: %User{} = user}
        }
      ) do
    if user_can_access_person_details?(person, user) do
      follows = Actors.list_paginated_follows_for_actor(person, page, limit)
      {:ok, follows}
    else
      {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @spec user_for_person(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, User.t() | nil} | {:error, String.t() | nil}
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
        {:error, :user_not_found}
    end
  end

  def user_for_person(_, _args, _resolution), do: {:error, nil}

  @spec organized_events_for_person(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Event.t())} | {:error, :unauthorized}
  def organized_events_for_person(
        %Actor{} = person,
        %{page: page, limit: limit},
        %{
          context: %{current_user: %User{} = user}
        }
      ) do
    if user_can_access_person_details?(person, user) do
      %Page{} = page = Events.list_organized_events_for_actor(person, page, limit)
      {:ok, page}
    else
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

  @spec user_can_access_person_details?(Actor.t(), User.t()) :: boolean()
  defp user_can_access_person_details?(%Actor{}, %User{role: role}) when is_moderator(role),
    do: true

  defp user_can_access_person_details?(%Actor{type: :Person, user_id: actor_user_id}, %User{
         id: user_id
       })
       when not is_nil(user_id),
       do: actor_user_id == user_id

  defp user_can_access_person_details?(_, _), do: false

  @spec group_from_args(map()) :: Actor.t() | nil
  defp group_from_args(%{group: group}) do
    Actors.get_actor_by_name(group, :Group)
  end

  defp group_from_args(%{group_id: group_id}) do
    Actors.get_actor(group_id)
  end

  defp group_from_args(_) do
    :none
  end
end
