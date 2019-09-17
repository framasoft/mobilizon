defmodule MobilizonWeb.Cache do
  @moduledoc """
  Facade module which provides access to all cached data.
  """

  alias Mobilizon.Actors.Actor

  alias MobilizonWeb.Cache.ActivityPub

  @caches [:activity_pub, :feed, :ics]

  @doc """
  Clears all caches for an actor.
  """
  @spec clear_cache(Actor.t()) :: {:ok, true}
  def clear_cache(%Actor{preferred_username: preferred_username, domain: nil}) do
    Enum.each(@caches, &Cachex.del(&1, "actor_" <> preferred_username))
  end

  defdelegate get_local_actor_by_name(name), to: ActivityPub
  defdelegate get_public_event_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_comment_by_uuid_with_preload(uuid), to: ActivityPub
  defdelegate get_relay, to: ActivityPub
end
