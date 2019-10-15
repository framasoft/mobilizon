defmodule Mobilizon.Service.Export.Feed do
  @moduledoc """
  Serve Atom Syndication Feeds.
  """

  import MobilizonWeb.Gettext

  alias Atomex.{Entry, Feed}

  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Users.User

  alias MobilizonWeb.{Endpoint, MediaProxy}
  alias MobilizonWeb.Router.Helpers, as: Routes

  require Logger

  @version Mix.Project.config()[:version]
  def version, do: @version

  @spec create_cache(String.t()) :: {:commit, String.t()} | {:ignore, any()}
  def create_cache("actor_" <> name) do
    case fetch_actor_event_feed(name) do
      {:ok, res} ->
        {:commit, res}

      err ->
        {:ignore, err}
    end
  end

  @spec create_cache(String.t()) :: {:commit, String.t()} | {:ignore, any()}
  def create_cache("token_" <> token) do
    case fetch_events_from_token(token) do
      {:ok, res} ->
        {:commit, res}

      err ->
        {:ignore, err}
    end
  end

  @spec fetch_actor_event_feed(String.t()) :: String.t()
  defp fetch_actor_event_feed(name) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name),
         {:visibility, true} <- {:visibility, Actor.is_public_visibility(actor)},
         {:ok, events, _count} <- Events.list_public_events_for_actor(actor) do
      {:ok, build_actor_feed(actor, events)}
    else
      err ->
        {:error, err}
    end
  end

  # Build an atom feed from actor and its public events
  @spec build_actor_feed(Actor.t(), list(), boolean()) :: String.t()
  defp build_actor_feed(%Actor{} = actor, events, public \\ true) do
    display_name = Actor.display_name(actor)

    self_url =
      Endpoint
      |> Routes.feed_url(:actor, actor.preferred_username, "atom")
      |> URI.decode()

    title =
      if public,
        do: "%{actor}'s public events feed on Mobilizon",
        else: "%{actor}'s private events feed on Mobilizon"

    # Title uses default instance language
    feed =
      self_url
      |> Feed.new(
        DateTime.utc_now(),
        Gettext.gettext(MobilizonWeb.Gettext, title, actor: display_name)
      )
      |> Feed.author(display_name, uri: actor.url)
      |> Feed.link(self_url, rel: "self")
      |> Feed.link(actor.url, rel: "alternate")
      |> Feed.generator("Mobilizon", uri: "https://joinmobilizon.org", version: version())
      |> Feed.entries(Enum.map(events, &get_entry/1))

    feed =
      if actor.avatar do
        feed |> Feed.icon(actor.avatar.url |> MediaProxy.url())
      else
        feed
      end

    feed =
      if actor.banner do
        feed |> Feed.logo(actor.banner.url |> MediaProxy.url())
      else
        feed
      end

    feed
    |> Feed.build()
    |> Atomex.generate_document()
  end

  # Create an entry for the Atom feed
  @spec get_entry(Event.t()) :: any()
  defp get_entry(%Event{} = event) do
    description = event.description || ""

    entry =
      event.url
      |> Entry.new(event.publish_at || event.inserted_at, event.title)
      |> Entry.link(event.url, rel: "alternate", type: "text/html")
      |> Entry.content({:cdata, description}, type: "html")
      |> Entry.published(event.publish_at || event.inserted_at)

    # Add tags
    entry =
      event.tags
      |> Enum.uniq()
      |> Enum.reduce(entry, fn tag, acc -> Entry.category(acc, tag.slug, label: tag.title) end)

    Entry.build(entry)
  end

  @spec fetch_events_from_token(String.t()) :: String.t()
  defp fetch_events_from_token(token) do
    with {:ok, _uuid} <- Ecto.UUID.cast(token),
         %FeedToken{actor: actor, user: %User{} = user} <- Events.get_feed_token(token) do
      case actor do
        %Actor{} = actor ->
          events = actor |> fetch_identity_participations() |> participations_to_events()
          {:ok, build_actor_feed(actor, events, false)}

        nil ->
          with actors <- Users.get_actors_for_user(user),
               events <-
                 actors
                 |> Enum.map(fn actor ->
                   actor
                   |> Events.list_event_participations_for_actor()
                   |> participations_to_events()
                 end)
                 |> Enum.concat() do
            {:ok, build_user_feed(events, user, token)}
          end
      end
    end
  end

  defp fetch_identity_participations(%Actor{} = actor) do
    with events <- Events.list_event_participations_for_actor(actor) do
      events
    end
  end

  defp participations_to_events(participations) do
    participations
    |> Enum.map(& &1.event_id)
    |> Enum.map(&Events.get_event_with_preload!/1)
  end

  # Build an atom feed from actor and its public events
  @spec build_user_feed(list(), User.t(), String.t()) :: String.t()
  defp build_user_feed(events, %User{email: email}, token) do
    self_url = Endpoint |> Routes.feed_url(:going, token, "atom") |> URI.decode()

    # Title uses default instance language
    self_url
    |> Feed.new(DateTime.utc_now(), gettext("Feed for %{email} on Mobilizon", email: email))
    |> Feed.link(self_url, rel: "self")
    |> Feed.generator("Mobilizon", uri: "https://joinmobilizon.org", version: version())
    |> Feed.entries(Enum.map(events, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end
end
