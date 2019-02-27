defmodule MobilizonWeb.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use MobilizonWeb, :controller

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Atomex.{Feed, Entry}
  import MobilizonWeb.Gettext

  @version Mix.Project.config()[:version]
  def version(), do: @version

  def actor(conn, %{"name" => name, "_format" => format}) when format in ["atom"] do
    name = String.replace_suffix(name, ".atom", "")

    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:mobilizon, "actor_" <> format <> "_" <> name, &create_cache/1) do
      conn
      |> put_resp_content_type("application/atom+xml")
      |> send_resp(200, data)
    else
      _err ->
        send_resp(conn, 404, "Not found")
    end
  end

  @spec create_cache(String.t()) :: {:commit, String.t()} | {:ignore, any()}
  defp create_cache(key) do
    with ["actor", type, name] <- String.split(key, "_", parts: 3),
         {:ok, res} <- fetch_actor_event_feed(type, name) do
      {:commit, res}
    else
      err ->
        {:ignore, err}
    end
  end

  @spec fetch_actor_event_feed(String.t(), String.t()) :: String.t()
  defp fetch_actor_event_feed(type, name) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name),
         {:ok, events, _count} <- Events.get_public_events_for_actor(actor) do
      {:ok, build_actor_feed(actor, events, type)}
    else
      err ->
        {:error, err}
    end
  end

  @spec build_actor_feed(Actor.t(), list(), String.t()) :: String.t()
  defp build_actor_feed(%Actor{} = actor, events, type) do
    display_name = Actor.display_name(actor)

    # Title uses default instance language
    feed =
      Feed.new(
        actor.url <> ".rss",
        DateTime.utc_now(),
        gettext("%{actor}'s public events feed", actor: display_name)
      )
      |> Feed.author(display_name, uri: actor.url)
      |> Feed.link(actor.url <> "." <> type, rel: "self")
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

  defp get_entry(%Event{} = event) do
    with {:ok, html, []} <- Earmark.as_html(event.description) do
      entry =
        Entry.new(event.url, event.inserted_at, event.title)
        |> Entry.link(event.url, rel: "alternate", type: "text/html")
        |> Entry.content({:cdata, html}, type: "html")

      entry = if event.publish_at, do: Entry.published(entry, event.publish_at), else: entry

      # Add tags
      entry =
        event.tags
        |> Enum.map(& &1.title)
        |> Enum.uniq()
        |> Enum.reduce(entry, fn tag, acc -> Entry.category(acc, tag) end)

      Entry.build(entry)
    else
      {:error, _html, error_messages} ->
        require Logger
        Logger.error("Unable to produce HTML for Markdown", details: inspect(error_messages))
    end
  end
end
