defmodule Mobilizon.GraphQL.Resolvers.Group do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.Config
  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.GraphQL.API
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Upload
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find a group
  """
  @spec find_group(
          any,
          %{:preferred_username => binary, optional(any) => any},
          Absinthe.Resolution.t()
        ) ::
          {:error, :group_not_found} | {:ok, Actor.t()}
  def find_group(
        parent,
        %{preferred_username: name} = args,
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    case ActivityPubActor.find_or_make_group_from_nickname(name) do
      {:ok, %Actor{id: group_id, suspended: false} = group} ->
        if Actors.member?(actor_id, group_id) do
          {:ok, group}
        else
          find_group(parent, args, nil)
        end

      {:ok, %Actor{}} ->
        {:error, :group_not_found}

      {:error, err} ->
        Logger.debug("Unable to find group, #{inspect(err)}")
        {:error, :group_not_found}
    end
  end

  def find_group(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPubActor.find_or_make_group_from_nickname(name) do
      {:ok, %Actor{suspended: false} = actor} ->
        %Actor{} = actor = restrict_fields_for_non_member_request(actor)
        {:ok, actor}

      {:ok, %Actor{}} ->
        {:error, :group_not_found}

      {:error, err} ->
        Logger.debug("Unable to find group, #{inspect(err)}")
        {:error, :group_not_found}
    end
  end

  def find_group_by_id(_parent, %{id: id}, %{
        context: %{
          current_actor: %Actor{id: actor_id}
        }
      }) do
    with %Actor{suspended: false, id: group_id} = group <- Actors.get_actor_with_preload(id),
         true <- Actors.member?(actor_id, group_id) do
      {:ok, group}
    else
      _ ->
        {:error, :group_not_found}
    end
  end

  def find_group_by_id(_parent, _args, _resolution) do
    {:error, :group_not_found}
  end

  @doc """
  Get a group
  """
  @spec get_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def get_group(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}}) do
    case Actors.get_actor_with_preload(id, true) do
      %Actor{type: :Group, suspended: suspended} = actor ->
        if suspended == false or is_moderator(role) do
          {:ok, actor}
        else
          {:error, dgettext("errors", "Group with ID %{id} not found", id: id)}
        end

      nil ->
        {:error, dgettext("errors", "Group with ID %{id} not found", id: id)}
    end
  end

  @doc """
  Lists all groups
  """
  @spec list_groups(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Actor.t())} | {:error, String.t()}
  def list_groups(
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
     Actors.list_actors(:Group, preferred_username, name, domain, local, suspended, page, limit)}
  end

  def list_groups(_parent, _args, _resolution),
    do: {:error, dgettext("errors", "You may not list groups unless moderator.")}

  # TODO Move me to somewhere cleaner
  @spec save_attached_pictures(map()) :: map()
  defp save_attached_pictures(args) do
    Enum.reduce([:avatar, :banner], args, fn key, args ->
      if is_map(args) && Map.has_key?(args, key) && !is_nil(args[key][:media]) do
        pic = args[key][:media]

        with {:ok, %{name: name, url: url, content_type: content_type, size: _size}} <-
               Upload.store(pic.file, type: key, description: pic.alt) do
          Logger.debug("Uploaded #{name} to #{url}")
          Map.put(args, key, %{name: name, url: url, content_type: content_type})
        end
      else
        Logger.debug("No picture upload")
        args
      end
    end)
  end

  @doc """
  Create a new group. The creator is automatically added as admin
  """
  @spec create_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def create_group(
        _parent,
        args,
        %{
          context: %{
            current_actor: %Actor{id: creator_actor_id} = creator_actor,
            current_user: %User{role: role} = _resolution
          }
        }
      ) do
    if can_create_group?(role) do
      args =
        args
        |> Map.update(:preferred_username, "", &String.downcase/1)
        |> Map.put(:creator_actor, creator_actor)
        |> Map.put(:creator_actor_id, creator_actor_id)

      with {:picture, args} when is_map(args) <- {:picture, save_attached_pictures(args)},
           {:ok, _activity, %Actor{type: :Group} = group} <-
             API.Groups.create_group(args) do
        {:ok, group}
      else
        {:picture, {:error, :file_too_large}} ->
          {:error, dgettext("errors", "The provided picture is too heavy")}

        {:error, err} ->
          {:error, err}
      end
    else
      {:error, dgettext("errors", "Only admins can create groups")}
    end
  end

  def create_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create a group"}
  end

  @spec can_create_group?(atom()) :: boolean()
  defp can_create_group?(role) do
    if Config.only_admin_can_create_groups?() do
      is_admin(role)
    else
      true
    end
  end

  @doc """
  Update a group. The creator is automatically added as admin
  """
  @spec update_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def update_group(
        _parent,
        %{id: group_id} = args,
        %{
          context: %{
            current_actor: %Actor{} = updater_actor
          }
        }
      ) do
    if Actors.administrator?(updater_actor.id, group_id) do
      args = Map.put(args, :updater_actor, updater_actor)

      case save_attached_pictures(args) do
        {:error, :file_too_large} ->
          {:error, dgettext("errors", "The provided picture is too heavy")}

        args when is_map(args) ->
          case API.Groups.update_group(args) do
            {:ok, _activity, %Actor{type: :Group} = group} ->
              {:ok, group}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:error, changeset}

            {:error, err} ->
              Logger.info("Failed to update group #{inspect(group_id)}")
              Logger.debug(inspect(err))
              {:error, dgettext("errors", "Failed to update the group")}
          end
      end
    else
      Logger.info(
        "Profile #{updater_actor.id} tried to update group #{group_id}, but they are not admin"
      )

      {:error, dgettext("errors", "Profile is not administrator for the group")}
    end
  end

  def update_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update a group")}
  end

  @doc """
  Delete an existing group
  """
  @spec delete_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, %{id: integer()}} | {:error, String.t()}
  def delete_group(
        _parent,
        %{group_id: group_id},
        %{
          context: %{
            current_actor: %Actor{id: actor_id} = actor
          }
        }
      ) do
    with {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:ok, %Member{} = member} <- Actors.get_member(actor_id, group.id),
         {:is_admin, true} <- {:is_admin, Member.administrator?(member)},
         {:ok, _activity, group} <- Actions.Delete.delete(group, actor, true) do
      {:ok, %{id: group.id}}
    else
      {:error, :group_not_found} ->
        {:error, dgettext("errors", "Group not found")}

      {:error, :member_not_found} ->
        {:error, dgettext("errors", "Current profile is not a member of this group")}

      {:is_admin, false} ->
        {:error,
         dgettext("errors", "Current profile is not an administrator of the selected group")}
    end
  end

  def delete_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to delete a group")}
  end

  @doc """
  Join an existing group
  """
  @spec join_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def join_group(_parent, %{group_id: group_id} = args, %{
        context: %{current_actor: %Actor{} = actor}
      }) do
    with {:ok, %Actor{type: :Group} = group} <-
           Actors.get_group_by_actor_id(group_id),
         {:error, :member_not_found} <- Actors.get_member(actor.id, group.id),
         {:is_able_to_join, true} <- {:is_able_to_join, Member.can_be_joined(group)},
         {:ok, _activity, %Member{} = member} <-
           Actions.Join.join(group, actor, true, args) do
      {:ok, member}
    else
      {:error, :group_not_found} ->
        {:error, dgettext("errors", "Group not found")}

      {:is_able_to_join, false} ->
        {:error, dgettext("errors", "You cannot join this group")}

      {:ok, %Member{}} ->
        {:error, dgettext("errors", "You are already a member of this group")}
    end
  end

  def join_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to join a group")}
  end

  @doc """
  Leave a existing group
  """
  @spec leave_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def leave_group(
        _parent,
        %{group_id: group_id},
        %{
          context: %{
            current_actor: %Actor{} = actor
          }
        }
      ) do
    with {:group, %Actor{type: :Group} = group} <- {:group, Actors.get_actor(group_id)},
         {:ok, _activity, %Member{} = member} <-
           Actions.Leave.leave(group, actor, true) do
      {:ok, member}
    else
      {:error, :member_not_found} ->
        {:error, dgettext("errors", "Member not found")}

      {:group, nil} ->
        {:error, dgettext("errors", "Group not found")}

      # Actions.Leave.leave can also return nil if the member isn't found. Probably something to fix.
      nil ->
        {:error, dgettext("errors", "Member not found")}

      {:error, :is_not_only_admin} ->
        {:error,
         dgettext("errors", "You can't leave this group because you are the only administrator")}
    end
  end

  def leave_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to leave a group")}
  end

  @doc """
  Follow a group
  """
  @spec follow_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Follower.t()} | {:error, String.t()}
  def follow_group(_parent, %{group_id: group_id, notify: _notify}, %{
        context: %{current_actor: %Actor{} = actor}
      }) do
    case Actors.get_actor(group_id) do
      %Actor{type: :Group} = group ->
        case Actions.Follow.follow(actor, group) do
          {:ok, _activity, %Follower{} = follower} ->
            {:ok, follower}

          {:error, :already_following} ->
            {:error, dgettext("errors", "You are already following this group")}
        end

      nil ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  def follow_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to follow a group")}
  end

  @doc """
  Update a group follow
  """
  @spec update_group_follow(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def update_group_follow(_parent, %{follow_id: follow_id, notify: notify}, %{
        context: %{current_actor: %Actor{} = actor}
      }) do
    case Actors.get_follower(follow_id) do
      %Follower{} = follower ->
        if follower.actor_id == actor.id do
          # Update notify
          Actors.update_follower(follower, %{notify: notify})
        else
          {:error, dgettext("errors", "Follow does not match your account")}
        end

      nil ->
        {:error, dgettext("errors", "Follow not found")}
    end
  end

  def update_group_follow(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update a group follow")}
  end

  @doc """
  Unfollow a group
  """
  @spec unfollow_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Follower.t()} | {:error, String.t()}
  def unfollow_group(_parent, %{group_id: group_id}, %{
        context: %{current_actor: %Actor{} = actor}
      }) do
    case Actors.get_actor(group_id) do
      %Actor{type: :Group} = group ->
        with {:ok, _activity, %Follower{} = follower} <- Actions.Follow.unfollow(actor, group) do
          {:ok, follower}
        end

      nil ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  def unfollow_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to unfollow a group")}
  end

  @spec find_events_for_group(Actor.t(), map(), Absinthe.Resolution.t() | nil) ::
          {:ok, Page.t(Event.t())}
  def find_events_for_group(
        %Actor{id: group_id} = group,
        %{
          page: page,
          limit: limit,
          order: order,
          order_direction: order_direction
        } = args,
        %{
          context: %{
            current_user: %User{},
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    if Actors.member?(actor_id, group_id) do
      {:ok,
       Events.list_organized_events_for_group(
         group,
         :all,
         Map.get(args, :after_datetime),
         Map.get(args, :before_datetime),
         order,
         order_direction,
         page,
         limit
       )}
    else
      find_events_for_group(group, args, nil)
    end
  end

  def find_events_for_group(
        %Actor{} = group,
        %{
          page: page,
          limit: limit,
          order: order,
          order_direction: order_direction
        } = args,
        _resolution
      ) do
    {:ok,
     Events.list_organized_events_for_group(
       group,
       :public,
       Map.get(args, :after_datetime),
       Map.get(args, :before_datetime),
       order,
       order_direction,
       page,
       limit
     )}
  end

  @spec restrict_fields_for_non_member_request(Actor.t()) :: Actor.t()
  defp restrict_fields_for_non_member_request(%Actor{} = group) do
    %Actor{
      group
      | followers: [],
        followings: [],
        organized_events: [],
        comments: [],
        feed_tokens: []
    }
  end
end
