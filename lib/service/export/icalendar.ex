defmodule Mobilizon.Service.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.{Config, Events}
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.Service.Export.Common
  alias Mobilizon.Service.Formatter.HTML

  @item_limit 500

  @doc """
  Create cache for an actor, an event or an user token
  """
  @spec create_cache(String.t()) :: {:commit, String.t()} | {:ignore, atom()}
  def create_cache("actor_" <> name) do
    case export_public_actor(name) do
      {:ok, res} ->
        {:commit, res}

      {:error, err} ->
        {:ignore, err}
    end
  end

  def create_cache("event_" <> uuid) do
    with %Event{} = event <- Events.get_public_event_by_uuid_with_preload(uuid),
         {:ok, res} <- export_public_event(event) do
      {:commit, res}
    else
      {:error, err} ->
        {:ignore, err}

      nil ->
        {:ignore, :event_not_found}
    end
  end

  def create_cache("token_" <> token) do
    case fetch_events_from_token(token) do
      {:ok, res} ->
        {:commit, res}

      {:error, err} ->
        {:ignore, err}
    end
  end

  def create_cache("instance") do
    {:ok, res} = fetch_instance_feed()
    {:commit, res}
  end

  @spec fetch_instance_feed :: {:ok, String.t()}
  defp fetch_instance_feed do
    {:ok, events, _posts} = Common.fetch_instance_public_content(@item_limit)
    {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
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
  @spec export_public_event(Event.t()) :: {:ok, String.t()} | {:error, :event_not_public}
  def export_public_event(%Event{visibility: visibility} = event)
      when visibility in [:public, :unlisted] do
    {:ok, events_to_ics([event])}
  end

  def export_public_event(%Event{}), do: {:error, :event_not_public}

  # Export a public actor's events to iCalendar format.
  # The actor must have a visibility of `:public` or `:unlisted`, as well as the events
  @spec export_public_actor(String.t()) ::
          {:ok, String.t()} | {:error, :actor_not_public | :actor_not_found}
  defp export_public_actor(name, limit \\ @item_limit) do
    case Common.fetch_actor_event_feed(name, limit) do
      {:ok, _actor, events, _posts} ->
        {:ok, events_to_ics(events)}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_events_from_token(String.t(), integer()) ::
          {:ok, String.t()} | {:error, :actor_not_public | :actor_not_found}
  defp fetch_events_from_token(token, limit \\ @item_limit) do
    case Common.fetch_events_from_token(token, limit) do
      %{events: events} ->
        {:ok, events_to_ics(events)}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec events_to_ics(list(Events.t())) :: String.t()
  defp events_to_ics(events) do
    %ICalendar{events: events |> Enum.map(&do_export_event/1)}
    |> ICalendar.to_ics(vendor: vendor())
  end

  @spec do_export_event(Event.t()) :: ICalendar.Event.t()
  defp do_export_event(%Event{} = event) do
    icalendar_event = %ICalendar.Event{
      summary: event.title,
      dtstart: begins_on(event),
      dtstamp: event.publish_at || DateTime.utc_now(),
      dtend: ends_on(event),
      description: HTML.strip_tags(event.description),
      uid: event.uuid,
      url: event.url,
      organizer: organizer(event)
    }

    icalendar_event =
      if event.physical_address do
        %ICalendar.Event{
          icalendar_event
          | geo: Address.coords(event.physical_address),
            location: Address.representation(event.physical_address)
        }
      else
        icalendar_event
      end

    icalendar_event =
      if length(event.tags) > 0 do
        %ICalendar.Event{icalendar_event | categories: event.tags |> Enum.map(& &1.title)}
      else
        icalendar_event
      end

    icalendar_event
  end

  @spec vendor :: String.t()
  defp vendor do
    "Mobilizon #{Config.instance_version()}"
  end

  defp begins_on(%Event{begins_on: begins_on, options: %EventOptions{timezone: timezone}}) do
    shift_tz(begins_on, timezone)
  end

  defp ends_on(%Event{ends_on: ends_on, options: %EventOptions{timezone: timezone}}) do
    shift_tz(ends_on, timezone)
  end

  defp shift_tz(%DateTime{} = date, timezone) when is_binary(timezone) do
    DateTime.shift_zone!(date, timezone)
  end

  defp shift_tz(%DateTime{} = date, _), do: date

  defp organizer(%Event{attributed_to: %Actor{} = group}) do
    Actor.display_name(group)
  end

  defp organizer(%Event{organizer_actor: %Actor{} = profile}) do
    Actor.display_name(profile)
  end
end
