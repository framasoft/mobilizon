defmodule Mobilizon.Service.Export.Cachable do
  @moduledoc """
  Behavior that export modules that use caching should implement
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Export.{Feed, ICalendar}

  @callback create_cache(String.t()) :: any()

  @callback clear_caches(Event.t() | Post.t() | Actor.t()) :: any()

  @spec clear_all_caches(%{
          :__struct__ => Mobilizon.Actors.Actor | Mobilizon.Events.Event | Mobilizon.Posts.Post,
          optional(any) => any
        }) :: {:error, boolean} | {:ok, boolean}
  def clear_all_caches(entity) do
    Feed.clear_caches(entity)
    ICalendar.clear_caches(entity)
  end
end
