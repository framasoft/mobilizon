defmodule Mobilizon.Service.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format.
  """

  alias Mobilizon.{Actors, Config, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @vendor "Mobilizon #{Config.instance_version()}"

  @doc """
  Export a public event to iCalendar format.

  The event must have a visibility of `:public` or `:unlisted`
  """
  @spec export_public_event(Event.t()) :: {:ok, String.t()}
  def export_public_event(%Event{visibility: visibility} = event)
      when visibility in [:public, :unlisted] do
    export_event(event)
  end

  @spec export_public_event(Event.t()) :: {:error, :event_not_public}
  def export_public_event(%Event{}), do: {:error, :event_not_public}

  @doc """
  Export an event to iCalendar format
  """
  def export_event(%Event{} = event) do
    {:ok, %ICalendar{events: [do_export_event(event)]} |> ICalendar.to_ics(vendor: @vendor)}
  end

  @spec do_export_event(Event.t()) :: ICalendar.Event.t()
  defp do_export_event(%Event{} = event) do
    %ICalendar.Event{
      summary: event.title,
      dtstart: event.begins_on,
      dtstamp: event.publish_at || DateTime.utc_now(),
      dtend: event.ends_on,
      description: HTML.strip_tags(event.description),
      uid: event.uuid,
      url: event.url,
      geo: Address.coords(event.physical_address),
      location: Address.representation(event.physical_address),
      categories: event.tags |> Enum.map(& &1.title)
    }
  end

  @doc """
  Export a public actor's events to iCalendar format.

  The actor must have a visibility of `:public` or `:unlisted`, as well as the events
  """
  @spec export_public_actor(Actor.t()) :: String.t()
  def export_public_actor(%Actor{} = actor) do
    with {:visibility, true} <- {:visibility, Actor.is_public_visibility?(actor)},
         %Page{elements: events} <-
           Events.list_public_events_for_actor(actor) do
      {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
    end
  end

  @spec export_private_actor(Actor.t()) :: String.t()
  def export_private_actor(%Actor{} = actor) do
    with events <-
           actor |> Events.list_event_participations_for_actor() |> participations_to_events() do
      {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
    end
  end

  @doc """
  Create cache for an actor, an event or an user token
  """
  def create_cache("actor_" <> name) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name),
         {:ok, res} <- export_public_actor(actor) do
      {:commit, res}
    else
      err ->
        {:ignore, err}
    end
  end

  def create_cache("event_" <> uuid) do
    with %Event{} = event <- Events.get_public_event_by_uuid_with_preload(uuid),
         {:ok, res} <- export_public_event(event) do
      {:commit, res}
    else
      err ->
        {:ignore, err}
    end
  end

  def create_cache("token_" <> token) do
    case fetch_events_from_token(token) do
      {:ok, res} ->
        {:commit, res}

      err ->
        {:ignore, err}
    end
  end

  @spec fetch_events_from_token(String.t()) :: String.t()
  defp fetch_events_from_token(token) do
    with %FeedToken{actor: actor, user: %User{} = user} <- Events.get_feed_token(token) do
      case actor do
        %Actor{} = actor ->
          export_private_actor(actor)

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
            {:ok,
             %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
          end
      end
    end
  end

  defp participations_to_events(%Page{elements: participations}) do
    participations
    |> Enum.map(& &1.event_id)
    |> Enum.map(&Events.get_event_with_preload!/1)
  end
end
