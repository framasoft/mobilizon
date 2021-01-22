defmodule Mobilizon.GraphQL.Resolvers.Group do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.GraphQL.API
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Upload
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find a group
  """
  def find_group(
        parent,
        %{preferred_username: name} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:group, {:ok, %Actor{id: group_id} = group}} <-
           {:group, ActivityPub.find_or_make_group_from_nickname(name)},
         {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      {:ok, group}
    else
      {:member, false} ->
        find_group(parent, args, nil)

      {:group, _} ->
        {:error, :group_not_found}

      _ ->
        {:error, :unknown}
    end
  end

  def find_group(_parent, %{preferred_username: name}, _resolution) do
    with {:ok, actor} <- ActivityPub.find_or_make_group_from_nickname(name),
         %Actor{} = actor <- restrict_fields_for_non_member_request(actor) do
      {:ok, actor}
    else
      _ ->
        {:error, :group_not_found}
    end
  end

  @doc """
  Get a group
  """
  def get_group(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}}) do
    with %Actor{type: :Group, suspended: suspended} = actor <-
           Actors.get_actor_with_preload(id, true),
         true <- suspended == false or is_moderator(role) do
      {:ok, actor}
    else
      _ ->
        {:error, dgettext("errors", "Group with ID %{id} not found", id: id)}
    end
  end

  @doc """
  Lists all groups
  """
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
  defp save_attached_pictures(args) do
    Enum.reduce([:avatar, :banner], args, fn key, args ->
      if Map.has_key?(args, key) && !is_nil(args[key][:media]) do
        pic = args[key][:media]

        with {:ok, %{name: name, url: url, content_type: content_type, size: _size}} <-
               Upload.store(pic.file, type: key, description: pic.alt) do
          Map.put(args, key, %{"name" => name, "url" => url, "mediaType" => content_type})
        end
      else
        args
      end
    end)
  end

  @doc """
  Create a new group. The creator is automatically added as admin
  """
  def create_group(
        _parent,
        args,
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with %Actor{id: creator_actor_id} = creator_actor <- Users.get_actor_for_user(user),
         args <- Map.update(args, :preferred_username, "", &String.downcase/1),
         args <- Map.put(args, :creator_actor, creator_actor),
         args <- Map.put(args, :creator_actor_id, creator_actor_id),
         args <- save_attached_pictures(args),
         {:ok, _activity, %Actor{type: :Group} = group} <-
           API.Groups.create_group(args) do
      {:ok, group}
    else
      {:error, err} when is_binary(err) ->
        {:error, err}
    end
  end

  def create_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create a group"}
  end

  @doc """
  Update a group. The creator is automatically added as admin
  """
  def update_group(
        _parent,
        %{id: group_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with %Actor{} = updater_actor <- Users.get_actor_for_user(user),
         {:administrator, true} <-
           {:administrator, Actors.is_administrator?(updater_actor.id, group_id)},
         args <- Map.put(args, :updater_actor, updater_actor),
         args <- save_attached_pictures(args),
         {:ok, _activity, %Actor{type: :Group} = group} <-
           API.Groups.update_group(args) do
      {:ok, group}
    else
      {:error, err} when is_binary(err) ->
        {:error, err}

      {:administrator, false} ->
        {:error, dgettext("errors", "Profile is not administrator for the group")}
    end
  end

  def update_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update a group")}
  end

  @doc """
  Delete an existing group
  """
  def delete_group(
        _parent,
        %{group_id: group_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with %Actor{id: actor_id} = actor <- Users.get_actor_for_user(user),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:ok, %Member{} = member} <- Actors.get_member(actor_id, group.id),
         {:is_admin, true} <- {:is_admin, Member.is_administrator(member)},
         {:ok, _activity, group} <- ActivityPub.delete(group, actor, true) do
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
  def join_group(_parent, %{group_id: group_id} = args, %{
        context: %{current_user: %User{} = user}
      }) do
    with %Actor{} = actor <- Users.get_actor_for_user(user),
         {:ok, %Actor{type: :Group} = group} <-
           Actors.get_group_by_actor_id(group_id),
         {:error, :member_not_found} <- Actors.get_member(actor.id, group.id),
         {:is_able_to_join, true} <- {:is_able_to_join, Member.can_be_joined(group)},
         {:ok, _activity, %Member{} = member} <-
           ActivityPub.join(group, actor, true, args) do
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
  def leave_group(
        _parent,
        %{group_id: group_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{} = actor} <- {:actor, Users.get_actor_for_user(user)},
         {:group, %Actor{type: :Group} = group} <- {:group, Actors.get_actor(group_id)},
         {:ok, _activity, %Member{} = member} <- ActivityPub.leave(group, actor, true) do
      {:ok, member}
    else
      {:error, :member_not_found} ->
        {:error, dgettext("errors", "Member not found")}

      {:group, nil} ->
        {:error, dgettext("errors", "Group not found")}

      {:is_not_only_admin, false} ->
        {:error,
         dgettext("errors", "You can't leave this group because you are the only administrator")}
    end
  end

  def leave_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to leave a group")}
  end

  def find_events_for_group(
        %Actor{id: group_id} = group,
        %{
          page: page,
          limit: limit
        } = args,
        %{
          context: %{
            current_user: %User{role: user_role} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <-
           {:member, Actors.is_member?(actor_id, group_id) or is_moderator(user_role)} do
      # TODO : Handle public / restricted to group members events
      {:ok,
       Events.list_organized_events_for_group(
         group,
         :all,
         Map.get(args, :after_datetime),
         Map.get(args, :before_datetime),
         page,
         limit
       )}
    else
      {:member, false} ->
        find_events_for_group(group, args, nil)
    end
  end

  def find_events_for_group(
        %Actor{} = group,
        %{
          page: page,
          limit: limit
        } = args,
        _resolution
      ) do
    {:ok,
     Events.list_organized_events_for_group(
       group,
       :public,
       Map.get(args, :after_datetime),
       Map.get(args, :before_datetime),
       page,
       limit
     )}
  end

  defp restrict_fields_for_non_member_request(%Actor{} = group) do
    Map.merge(
      group,
      %{
        followers: [],
        followings: [],
        organized_events: [],
        comments: [],
        feed_tokens: []
      }
    )
  end
end
