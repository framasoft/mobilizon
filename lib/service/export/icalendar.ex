defmodule Mobilizon.Service.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.{Config, Events}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.Common
  alias Mobilizon.Service.Formatter.HTML

  @vendor "Mobilizon #{Config.instance_version()}"

  @doc """
  Create cache for an actor, an event or an user token
  """
  def create_cache("actor_" <> name) do
    case export_public_actor(name) do
      {:ok, res} ->
        {:commit, res}

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

  def create_cache("instance") do
    case fetch_instance_feed() do
      {:ok, res} ->
        {:commit, res}

      err ->
        {:ignore, err}
    end
  end

  @spec fetch_instance_feed :: {:ok, String.t()}
  defp fetch_instance_feed do
    case Common.fetch_instance_public_content() do
      {:ok, events, _posts} ->
        {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}

      err ->
        {:error, err}
    end
  end

  @doc """
  Export an event to iCalendar format.
  """
  @spec export_event(Event.t()) :: {:ok, String.t()}
  def export_event(%Event{} = event), do: {:ok, events_to_ics([event])}

  @doc """
  Export a public event to iCalendar format.

  The event must have a visibility of `:public` or `:unlisted`
  """
  @spec export_public_event(Event.t()) :: {:ok, String.t()}
  def export_public_event(%Event{visibility: visibility} = event)
      when visibility in [:public, :unlisted] do
    {:ok, events_to_ics([event])}
  end

  @spec export_public_event(Event.t()) :: {:error, :event_not_public}
  def export_public_event(%Event{}), do: {:error, :event_not_public}

  @doc """
  Export a public actor's events to iCalendar format.

  The actor must have a visibility of `:public` or `:unlisted`, as well as the events
  """
  @spec export_public_actor(String.t()) :: String.t()
  def export_public_actor(name) do
    case Common.fetch_actor_event_feed(name) do
      {:ok, _actor, events, _posts} ->
        {:ok, events_to_ics(events)}

      err ->
        {:error, err}
    end
  end

  @spec export_private_actor(Actor.t()) :: String.t()
  def export_private_actor(%Actor{} = actor) do
    with events <- Common.fetch_actor_private_events(actor) do
      {:ok, events_to_ics(events)}
    end
  end

  @spec fetch_events_from_token(String.t()) :: String.t()
  defp fetch_events_from_token(token) do
    with %{events: events} <- Common.fetch_events_from_token(token) do
      {:ok, events_to_ics(events)}
    end
  end

  @spec events_to_ics(list(Events.t())) :: String.t()
  defp events_to_ics(events) do
    %ICalendar{events: events |> Enum.map(&do_export_event/1)}
    |> ICalendar.to_ics(vendor: @vendor)
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
end
