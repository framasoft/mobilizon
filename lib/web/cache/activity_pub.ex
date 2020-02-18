defmodule Mobilizon.Web.Cache.ActivityPub do
  @moduledoc """
  ActivityPub related cache.
  """

  alias Mobilizon.{Actors, Conversations, Events, Resources, Todos, Tombstone}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @cache :activity_pub

  @doc """
  Gets a local actor by username.
  """
  @spec get_local_actor_by_name(String.t()) ::
          {:commit, Actor.t()} | {:ignore, nil}
  def get_local_actor_by_name(name) do
    Cachex.fetch(@cache, "actor_" <> name, fn "actor_" <> name ->
      case Actors.get_local_actor_by_name(name) do
        %Actor{} = actor ->
          {:commit, actor}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a public event by its UUID, with all associations loaded.
  """
  @spec get_public_event_by_uuid_with_preload(String.t()) ::
          {:commit, Event.t()} | {:ignore, nil}
  def get_public_event_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "event_" <> uuid, fn "event_" <> uuid ->
      case Events.get_public_event_by_uuid_with_preload(uuid) do
        %Event{} = event ->
          {:commit, event}

        nil ->
          with url <- Routes.page_url(Endpoint, :event, uuid),
               %Tombstone{} = tomstone <- Tombstone.find_tombstone(url) do
            tomstone
          else
            _ -> {:ignore, nil}
          end
      end
    end)
  end

  @doc """
  Gets a comment by its UUID, with all associations loaded.
  """
  @spec get_comment_by_uuid_with_preload(String.t()) ::
          {:commit, Comment.t()} | {:ignore, nil}
  def get_comment_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "comment_" <> uuid, fn "comment_" <> uuid ->
      case Conversations.get_comment_from_uuid_with_preload(uuid) do
        %Comment{} = comment ->
          {:commit, comment}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a resource by its UUID, with all associations loaded.
  """
  @spec get_resource_by_uuid_with_preload(String.t()) ::
          {:commit, Resource.t()} | {:ignore, nil}
  def get_resource_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "resource_" <> uuid, fn "resource_" <> uuid ->
      case Resources.get_resource_with_preloads(uuid) do
        %Resource{} = resource ->
          {:commit, resource}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a todo list by its UUID, with all associations loaded.
  """
  @spec get_todo_list_by_uuid_with_preload(String.t()) ::
          {:commit, TodoList.t()} | {:ignore, nil}
  def get_todo_list_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "todo_list_" <> uuid, fn "todo_list_" <> uuid ->
      case Todos.get_todo_list(uuid) do
        %TodoList{} = todo_list ->
          {:commit, todo_list}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a todo by its UUID, with all associations loaded.
  """
  @spec get_todo_by_uuid_with_preload(String.t()) ::
          {:commit, Todo.t()} | {:ignore, nil}
  def get_todo_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "todo_" <> uuid, fn "todo_" <> uuid ->
      case Todos.get_todo(uuid) do
        %Todo{} = todo ->
          {:commit, todo}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a relay.
  """
  @spec get_relay :: {:commit, Actor.t()} | {:ignore, nil}
  def get_relay do
    Cachex.fetch(@cache, "relay_actor", &Relay.get_actor/0)
  end
end
