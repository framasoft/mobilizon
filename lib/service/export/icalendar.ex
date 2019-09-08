defmodule Mobilizon.Service.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format
  """

  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Events
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors
  alias Mobilizon.Users.User
  alias Mobilizon.Users

  @doc """
  Export a public event to iCalendar format.

  The event must have a visibility of `:public` or `:unlisted`
  """
  @spec export_public_event(Event.t()) :: {:ok, String.t()}
  def export_public_event(%Event{visibility: visibility} = event)
      when visibility in [:public, :unlisted] do
    {:ok, %ICalendar{events: [do_export_event(event)]} |> ICalendar.to_ics(vendor: "Mobilizon")}
  end

  @spec export_public_event(Event.t()) :: {:error, :event_not_public}
  def export_public_event(%Event{}), do: {:error, :event_not_public}

  @spec do_export_event(Event.t()) :: ICalendar.Event.t()
  defp do_export_event(%Event{} = event) do
    %ICalendar.Event{
      summary: event.title,
      dtstart: event.begins_on,
      dtstamp: event.publish_at || DateTime.utc_now(),
      dtend: event.ends_on,
      description: event.description,
      uid: event.uuid,
      categories: [event.category] ++ (event.tags |> Enum.map(& &1.slug))
    }
  end

  @doc """
  Export a public actor's events to iCalendar format.

  The actor must have a visibility of `:public` or `:unlisted`, as well as the events
  """
  @spec export_public_actor(Actor.t()) :: String.t()
  def export_public_actor(%Actor{} = actor) do
    with true <- Actor.is_public_visibility(actor),
         {:ok, events, _} <- Events.get_public_events_for_actor(actor) do
      {:ok, %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
    end
  end

  @spec export_private_actor(Actor.t()) :: String.t()
  def export_private_actor(%Actor{} = actor) do
    with events <- Events.list_event_participations_for_actor(actor) do
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

  @doc """
  Create cache for an actor
  """
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
                 |> Enum.map(&Events.list_event_participations_for_actor/1)
                 |> Enum.concat() do
            {:ok,
             %ICalendar{events: events |> Enum.map(&do_export_event/1)} |> ICalendar.to_ics()}
          end
      end
    end
  end
end
