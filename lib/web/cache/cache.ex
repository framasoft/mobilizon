defmodule Mobilizon.Web.Cache do
  @moduledoc """
  Facade module which provides access to all cached data.
  """

  alias Mobilizon.Actors.Actor

  alias Mobilizon.Web.Cache.ActivityPub

  @caches [:activity_pub, :feed, :ics]

  @doc """
  Clears all caches for an actor.
  """
  @spec clear_cache(Actor.t()) :: {:ok, true}
  def clear_cache(%Actor{preferred_username: preferred_username, domain: nil}) do
    Enum.each(@caches, &Cachex.del(&1, "actor_" <> preferred_username))
  end

  defdelegate get_actor_by_name(name), to: ActivityPub
  defdelegate get_local_actor_by_name(name), to: ActivityPub
  defdelegate get_public_event_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_comment_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_resource_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_todo_list_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_todo_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_member_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_post_by_slug_with_preload(slug), to: ActivityPub
  defdelegate get_discussion_by_slug_with_preload(slug), to: ActivityPub
  defdelegate get_relay, to: ActivityPub
end
