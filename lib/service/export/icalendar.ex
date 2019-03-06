defmodule Mobilizon.Service.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format
  """

  alias Mobilizon.Events.Event
  alias Mobilizon.Events
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors

  @doc """
  Export a public event to iCalendar format.

  The event must have a visibility of `:public` or `:unlisted`
  """
  @spec export_public_event(Event.t()) :: {:ok, String.t()}
  def export_public_event(%Event{visibility: visibility} = event)
      when visibility in [:public, :unlisted] do
    {:ok, %ICalendar{events: [do_export_event(event)]} |> ICalendar.to_ics()}
  end

  @spec export_public_event(Event.t()) :: {:error, :event_not_public}
  def export_public_event(%Event{}), do: {:error, :event_not_public}

  @spec do_export_event(Event.t()) :: ICalendar.Event.t()
  defp do_export_event(%Event{} = event) do
    %ICalendar.Event{
      summary: event.title,
      dtstart: event.begins_on,
      dtend: event.ends_on,
      description: event.description,
      uid: event.uuid,
      categories: [event.category] ++ (event.tags |> Enum.map(& &1.slug))
    }
  end

  @doc """
  Export a public actor's events to iCalendar format.

  The events must have a visibility of `:public` or `:unlisted`
  """
  # TODO: The actor should also have visibility options
  @spec export_public_actor(Actor.t()) :: String.t()
  def export_public_actor(%Actor{} = actor) do
    with {:ok, events, _} <- Events.get_public_events_for_actor(actor) do
      {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
    end
  end

  @doc """
  Create cache for an actor
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

  @doc """
  Create cache for an actor
  """
  def create_cache("event_" <> uuid) do
    with %Event{} = event <- Events.get_event_full_by_uuid(uuid),
         {:ok, res} <- export_public_event(event) do
      {:commit, res}
    else
      err ->
        {:ignore, err}
    end
  end
end
