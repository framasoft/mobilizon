defmodule Mobilizon.GraphQL.Resolvers.Post do
  @moduledoc """
  Handles the posts-related GraphQL calls
  """

  alias Mobilizon.{Actors, Posts, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  require Logger

  @public_accessible_visibilities [:public, :unlisted]

  @doc """
  Find posts for group.

  Returns only if actor requesting is a member of the group
  """
  def find_posts_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         %Page{} = page <- Posts.get_posts_for_group(group, page, limit) do
      {:ok, page}
    else
      {:member, _} ->
        find_posts_for_group(group, args, nil)
    end
  end

  def find_posts_for_group(
        %Actor{} = group,
        %{page: page, limit: limit},
        _resolution
      ) do
    with %Page{} = page <- Posts.get_public_posts_for_group(group, page, limit) do
      {:ok, page}
    end
  end

  def find_posts_for_group(
        _group,
        _args,
        _resolution
      ) do
    {:ok, %Page{total: 0, elements: []}}
  end

  def get_post(
        parent,
        %{slug: slug},
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with {:current_actor, %Actor{id: actor_id}} <-
           {:current_actor, Users.get_actor_for_user(user)},
         {:post, %Post{attributed_to: %Actor{id: group_id}} = post} <-
           {:post, Posts.get_post_by_slug_with_preloads(slug)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      {:ok, post}
    else
      {:member, false} -> get_post(parent, %{slug: slug}, nil)
      {:post, _} -> {:error, "No such post"}
    end
  end

  def get_post(
        _parent,
        %{slug: slug},
        _resolution
      ) do
    case {:post, Posts.get_post_by_slug_with_preloads(slug)} do
      {:post, %Post{visibility: visibility, draft: false} = post}
      when visibility in @public_accessible_visibilities ->
        {:ok, post}

      {:post, _} ->
        {:error, "No such post"}
    end
  end

  def get_post(_parent, _args, _resolution) do
    {:error, "No such post"}
  end

  def create_post(
        _parent,
        %{attributed_to_id: group_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Post{} = post} <-
           ActivityPub.create(
             :post,
             args
             |> Map.put(:author_id, actor_id)
             |> Map.put(:attributed_to_id, group_id),
             true,
             %{}
           ) do
      {:ok, post}
    else
      {:own_check, _} ->
        {:error, "Parent post doesn't match this group"}

      {:member, _} ->
        {:error, "Actor id is not member of group"}
    end
  end

  def create_post(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create posts"}
  end

  def update_post(
        _parent,
        %{id: id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with {:uuid, {:ok, _uuid}} <- {:uuid, Ecto.UUID.cast(id)},
         %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:post, %Post{attributed_to: %Actor{id: group_id}} = post} <-
           {:post, Posts.get_post_with_preloads(id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Post{} = post} <-
           ActivityPub.update(post, args, true, %{}) do
      {:ok, post}
    else
      {:uuid, :error} ->
        {:error, "Post ID is not a valid ID"}

      {:post, _} ->
        {:error, "Post doesn't exist"}

      {:member, _} ->
        {:error, "Actor id is not member of group"}
    end
  end

  def update_post(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to update posts"}
  end

  def delete_post(
        _parent,
        %{id: post_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with {:uuid, {:ok, _uuid}} <- {:uuid, Ecto.UUID.cast(post_id)},
         %Actor{id: actor_id} = actor <- Users.get_actor_for_user(user),
         {:post, %Post{attributed_to: %Actor{id: group_id}} = post} <-
           {:post, Posts.get_post_with_preloads(post_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Post{} = post} <-
           ActivityPub.delete(post, actor) do
      {:ok, post}
    else
      {:uuid, :error} ->
        {:error, "Post ID is not a valid ID"}

      {:post, _} ->
        {:error, "Post doesn't exist"}

      {:member, _} ->
        {:error, "Actor id is not member of group"}
    end
  end

  def delete_post(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete posts"}
  end
end
