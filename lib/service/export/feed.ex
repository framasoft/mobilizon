defmodule Mobilizon.Service.Export.Feed do
  @moduledoc """
  Serve Atom Syndication Feeds
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Atomex.{Feed, Entry}
  import MobilizonWeb.Gettext
  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

  @version Mix.Project.config()[:version]
  def version(), do: @version

  @spec create_cache(String.t()) :: {:commit, String.t()} | {:ignore, any()}
  def create_cache("actor_" <> name) do
    with {:ok, res} <- fetch_actor_event_feed(name) do
      {:commit, res}
    else
      err ->
        {:ignore, err}
    end
  end

  @spec fetch_actor_event_feed(String.t()) :: String.t()
  defp fetch_actor_event_feed(name) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name),
         {:ok, events, _count} <- Events.get_public_events_for_actor(actor) do
      {:ok, build_actor_feed(actor, events)}
    else
      err ->
        {:error, err}
    end
  end

  # Build an atom feed from actor and it's public events
  @spec build_actor_feed(Actor.t(), list()) :: String.t()
  defp build_actor_feed(%Actor{} = actor, events) do
    display_name = Actor.display_name(actor)
    self_url = Routes.feed_url(Endpoint, :actor, actor.preferred_username, "atom") |> URI.decode()

    # Title uses default instance language
    feed =
      Feed.new(
        self_url,
        DateTime.utc_now(),
        gettext("%{actor}'s public events feed", actor: display_name)
      )
      |> Feed.author(display_name, uri: actor.url)
      |> Feed.link(self_url, rel: "self")
      |> Feed.link(actor.url, rel: "alternate")
      |> Feed.generator("Mobilizon", uri: "https://joinmobilizon.org", version: version())
      |> Feed.entries(Enum.map(events, &get_entry/1))

    feed = if actor.avatar_url, do: Feed.icon(feed, actor.avatar_url), else: feed

    feed =
      if actor.banner_url,
        do: Feed.logo(feed, actor.banner_url),
        else: feed

    feed
    |> Feed.build()
    |> Atomex.generate_document()
  end

  # Create an entry for the Atom feed
  @spec get_entry(Event.t()) :: any()
  defp get_entry(%Event{} = event) do
    with {:ok, html, []} <- Earmark.as_html(event.description) do
      entry =
        Entry.new(event.url, event.publish_at || event.inserted_at, event.title)
        |> Entry.link(event.url, rel: "alternate", type: "text/html")
        |> Entry.content({:cdata, html}, type: "html")
        |> Entry.published(event.publish_at || event.inserted_at)

      # Add tags
      entry =
        event.tags
        |> Enum.uniq()
        |> Enum.reduce(entry, fn tag, acc -> Entry.category(acc, tag.slug, label: tag.title) end)

      Entry.build(entry)
    else
      {:error, _html, error_messages} ->
        require Logger
        Logger.error("Unable to produce HTML for Markdown", details: inspect(error_messages))
    end
  end
end
