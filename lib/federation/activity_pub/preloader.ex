defmodule Mobilizon.Federation.ActivityPub.Preloader do
  @moduledoc """
  Module to ensure entities are correctly preloaded
  """

  # TODO: Move me in a more appropriate place
  alias Mobilizon.{Actors, Discussions, Events, Resources}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.Event
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Tombstone

  def maybe_preload(%Event{url: url}),
    do: {:ok, Events.get_public_event_by_url_with_preload!(url)}

  def maybe_preload(%Comment{url: url}),
    do: {:ok, Discussions.get_comment_from_url_with_preload!(url)}

  def maybe_preload(%Discussion{} = discussion), do: {:ok, discussion}

  def maybe_preload(%Resource{url: url}),
    do: {:ok, Resources.get_resource_by_url_with_preloads(url)}

  def maybe_preload(%Actor{url: url}), do: {:ok, Actors.get_actor_by_url!(url, true)}

  def maybe_preload(%Tombstone{uri: _uri} = tombstone), do: {:ok, tombstone}

  def maybe_preload(other), do: {:error, other}
end
