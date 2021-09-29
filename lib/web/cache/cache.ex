defmodule Mobilizon.Web.Cache do
  @moduledoc """
  Facade module which provides access to all cached data.
  """

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}
  alias Mobilizon.Web.Cache.ActivityPub
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  @caches [:activity_pub, :feed, :ics]

  @type local_actor :: %Actor{domain: nil}

  @doc """
  Clears all caches for a local actor.
  """
  @spec clear_cache(%Actor{domain: nil, preferred_username: String.t()}) :: :ok
  def clear_cache(%Actor{preferred_username: preferred_username, domain: nil})
      when is_valid_string(preferred_username) do
    Enum.each(@caches, &Cachex.del(&1, "actor_" <> preferred_username))
  end

  @spec get_actor_by_name(binary) :: {:commit, Actor.t()} | {:ignore, nil}
  defdelegate get_actor_by_name(name), to: ActivityPub
  @spec get_local_actor_by_name(binary) :: {:commit, Actor.t()} | {:ignore, nil}
  defdelegate get_local_actor_by_name(name), to: ActivityPub
  @spec get_public_event_by_uuid_with_preload(binary) :: {:commit, Event.t()} | {:ignore, nil}
  defdelegate get_public_event_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_comment_by_uuid_with_preload(binary) :: {:commit, Comment.t()} | {:ignore, nil}
  defdelegate get_comment_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_resource_by_uuid_with_preload(binary) :: {:commit, Resource.t()} | {:ignore, nil}
  defdelegate get_resource_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_todo_list_by_uuid_with_preload(binary) :: {:commit, TodoList.t()} | {:ignore, nil}
  defdelegate get_todo_list_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_todo_by_uuid_with_preload(binary) :: {:commit, Todo.t()} | {:ignore, nil}
  defdelegate get_todo_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_member_by_uuid_with_preload(binary) :: {:commit, Member.t()} | {:ignore, nil}
  defdelegate get_member_by_uuid_with_preload(uuid), to: ActivityPub
  @spec get_post_by_slug_with_preload(binary) :: {:commit, Post.t()} | {:ignore, nil}
  defdelegate get_post_by_slug_with_preload(slug), to: ActivityPub
  @spec get_discussion_by_slug_with_preload(binary) :: {:commit, Discussion.t()} | {:ignore, nil}
  defdelegate get_discussion_by_slug_with_preload(slug), to: ActivityPub
  @spec get_relay :: {:commit, Actor.t()} | {:ignore, nil}
  defdelegate get_relay, to: ActivityPub
end
