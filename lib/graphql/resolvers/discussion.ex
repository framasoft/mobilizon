defmodule Mobilizon.GraphQL.Resolvers.Discussion do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Discussions, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.GraphQL.API.Comments
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  def find_discussions_for_actor(
        %Actor{id: group_id},
        _args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, %Actor{type: :Group} = group} <- Actors.get_group_by_actor_id(group_id) do
      {:ok, Discussions.find_discussions_for_actor(group)}
    else
      {:member, false} ->
        {:ok, %Page{total: 0, elements: []}}
    end
  end

  def find_discussions_for_actor(%Actor{}, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  def get_discussion(_parent, %{id: id}, %{
        context: %{
          current_user: %User{} = user
        }
      }) do
    with {:actor, %Actor{id: creator_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         %Discussion{actor_id: actor_id} = discussion <-
           Discussions.get_discussion(id),
         {:member, true} <- {:member, Actors.is_member?(creator_id, actor_id)} do
      {:ok, discussion}
    end
  end

  def get_discussion(_parent, %{slug: slug}, %{
        context: %{
          current_user: %User{} = user
        }
      }) do
    with {:actor, %Actor{id: creator_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         %Discussion{actor_id: actor_id} = discussion <-
           Discussions.get_discussion_by_slug(slug),
         {:member, true} <- {:member, Actors.is_member?(creator_id, actor_id)} do
      {:ok, discussion}
    else
      nil -> {:error, dgettext("errors", "Discussion not found")}
    end
  end

  def get_discussion(_parent, _args, %{
        context: %{
          current_user: %User{} = _user
        }
      }),
      do:
        {:error,
         dgettext("errors", "You must provide either an ID or a slug to access a discussion")}

  def get_discussion(_parent, _args, _resolution),
    do: {:error, dgettext("errors", "You need to be logged-in to access discussions")}

  def get_comments_for_discussion(
        %Discussion{id: discussion_id},
        %{page: page, limit: limit},
        _resolution
      ) do
    {:ok, Discussions.get_comments_for_discussion(discussion_id, page, limit)}
  end

  def create_discussion(
        _parent,
        %{title: title, text: text, actor_id: group_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: creator_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(creator_id, group_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           Comments.create_discussion(%{
             title: title,
             text: text,
             actor_id: group_id,
             creator_id: creator_id,
             attributed_to_id: group_id
           }) do
      {:ok, discussion}
    else
      {:member, false} ->
        {:error, :unauthorized}
    end
  end

  def reply_to_discussion(
        _parent,
        %{text: text, discussion_id: discussion_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: creator_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:no_discussion,
          %Discussion{
            actor_id: actor_id,
            last_comment: %Comment{
              id: last_comment_id,
              origin_comment_id: origin_comment_id,
              in_reply_to_comment_id: previous_in_reply_to_comment_id
            }
          } = _discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.is_member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           Comments.create_discussion(%{
             text: text,
             discussion_id: discussion_id,
             actor_id: creator_id,
             attributed_to_id: actor_id,
             in_reply_to_comment_id: last_comment_id,
             origin_comment_id:
               origin_comment_id || previous_in_reply_to_comment_id || last_comment_id
           }) do
      {:ok, discussion}
    end
  end

  @spec update_discussion(map(), map(), map()) :: {:ok, Discussion.t()}
  def update_discussion(
        _parent,
        %{title: title, discussion_id: discussion_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: creator_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:no_discussion, %Discussion{actor_id: actor_id} = discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.is_member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           ActivityPub.update(
             discussion,
             %{
               title: title
             }
           ) do
      {:ok, discussion}
    end
  end

  def delete_discussion(_parent, %{discussion_id: discussion_id}, %{
        context: %{
          current_user: %User{} = user
        }
      }) do
    with {:actor, %Actor{id: creator_id} = actor} <- {:actor, Users.get_actor_for_user(user)},
         {:no_discussion, %Discussion{actor_id: actor_id} = discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.is_member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           ActivityPub.delete(discussion, actor) do
      {:ok, discussion}
    else
      {:no_discussion, _} ->
        {:error, dgettext("errors", "No discussion with ID %{id}", id: discussion_id)}

      {:member, _} ->
        {:error,
         dgettext("errors", "You are not a member of the group the discussion belongs to")}
    end
  end
end
