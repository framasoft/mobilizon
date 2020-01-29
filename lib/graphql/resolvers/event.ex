defmodule Mobilizon.GraphQL.Resolvers.Event do
  @moduledoc """
  Handles the event-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, EventParticipantStats}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.API
  alias Mobilizon.GraphQL.Resolvers.Person

  alias Mobilizon.Federation.ActivityPub.Activity

  # We limit the max number of events that can be retrieved
  @event_max_limit 100
  @number_of_related_events 3

  def list_events(_parent, %{page: page, limit: limit}, _resolution)
      when limit < @event_max_limit do
    {:ok, Events.list_events(page, limit)}
  end

  def list_events(_parent, %{page: _page, limit: _limit}, _resolution) do
    {:error, :events_max_limit_reached}
  end

  defp find_private_event(
         _parent,
         %{uuid: uuid},
         %{context: %{current_user: %User{id: user_id}}} = _resolution
       ) do
    case {:has_event, Events.get_own_event_by_uuid_with_preload(uuid, user_id)} do
      {:has_event, %Event{} = event} ->
        {:ok, Map.put(event, :organizer_actor, Person.proxify_pictures(event.organizer_actor))}

      {:has_event, _} ->
        {:error, "Event with UUID #{uuid} not found"}
    end
  end

  defp find_private_event(_parent, %{uuid: uuid}, _resolution) do
    {:error, "Event with UUID #{uuid} not found"}
  end

  def find_event(parent, %{uuid: uuid} = args, resolution) do
    case {:has_event, Events.get_public_event_by_uuid_with_preload(uuid)} do
      {:has_event, %Event{} = event} ->
        {:ok, Map.put(event, :organizer_actor, Person.proxify_pictures(event.organizer_actor))}

      {:has_event, _} ->
        find_private_event(parent, args, resolution)
    end
  end

  @doc """
  List participants for event (through an event request)
  """
  def list_participants_for_event(
        %Event{id: event_id},
        %{page: page, limit: limit, roles: roles, actor_id: actor_id},
        %{context: %{current_user: %User{} = user}} = _resolution
      ) do
    with {:is_owned, %Actor{} = _actor} <- User.owns_actor(user, actor_id),
         # Check that moderator has right
         {:actor_approve_permission, true} <-
           {:actor_approve_permission, Events.moderator_for_event?(event_id, actor_id)} do
      roles =
        case roles do
          "" ->
            []

          roles ->
            roles
            |> String.split(",")
            |> Enum.map(&String.downcase/1)
            |> Enum.map(&String.to_existing_atom/1)
        end

      {:ok, Events.list_participants_for_event(event_id, roles, page, limit)}
    else
      {:is_owned, nil} ->
        {:error, "Moderator Actor ID is not owned by authenticated user"}

      {:actor_approve_permission, _} ->
        {:error, "Provided moderator actor ID doesn't have permission on this event"}
    end
  end

  def list_participants_for_event(_, _args, _resolution) do
    {:ok, []}
  end

  def stats_participants_going(%EventParticipantStats{} = stats, _args, _resolution) do
    {:ok, stats.participant + stats.moderator + stats.administrator + stats.creator}
  end

  @doc """
  List related events
  """
  def list_related_events(
        %Event{tags: tags, organizer_actor: organizer_actor, uuid: uuid},
        _args,
        _resolution
      ) do
    # We get the organizer's next public event
    events =
      [Events.get_upcoming_public_event_for_actor(organizer_actor, uuid)]
      |> Enum.filter(&is_map/1)

    # We find similar events with the same tags
    # uniq_by : It's possible event_from_same_actor is inside events_from_tags
    events =
      events
      |> Enum.concat(Events.list_events_by_tags(tags, @number_of_related_events))
      |> uniq_events()

    # TODO: We should use tag_relations to find more appropriate events

    # We've considered all recommended events, so we fetch the latest events
    events =
      if @number_of_related_events - length(events) > 0 do
        events
        |> Enum.concat(
          Events.list_events(1, @number_of_related_events, :begins_on, :asc, true, true)
        )
        |> uniq_events()
      else
        events
      end

    events =
      events
      # We remove the same event from the results
      |> Enum.filter(fn event -> event.uuid != uuid end)
      # We return only @number_of_related_events right now
      |> Enum.take(@number_of_related_events)

    {:ok, events}
  end

  defp uniq_events(events), do: Enum.uniq_by(events, fn event -> event.uuid end)

  @doc """
  Create an event
  """
  def create_event(
        _parent,
        %{organizer_actor_id: organizer_actor_id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    # See https://github.com/absinthe-graphql/absinthe/issues/490
    with args <- Map.put(args, :options, args[:options] || %{}),
         {:is_owned, %Actor{} = organizer_actor} <- User.owns_actor(user, organizer_actor_id),
         args_with_organizer <- Map.put(args, :organizer_actor, organizer_actor),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.create_event(args_with_organizer) do
      {:ok, event}
    else
      {:is_owned, nil} ->
        {:error, "Organizer actor id is not owned by the user"}

      {:error, _, %Ecto.Changeset{} = error, _} ->
        {:error, error}

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}
    end
  end

  def create_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create events"}
  end

  @doc """
  Update an event
  """
  def update_event(
        _parent,
        %{event_id: event_id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    # See https://github.com/absinthe-graphql/absinthe/issues/490
    with args <- Map.put(args, :options, args[:options] || %{}),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         organizer_actor_id <- args |> Map.get(:organizer_actor_id, event.organizer_actor_id),
         {:is_owned, %Actor{} = organizer_actor} <-
           User.owns_actor(user, organizer_actor_id),
         args <- Map.put(args, :organizer_actor, organizer_actor),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.update_event(args, event) do
      {:ok, event}
    else
      {:error, :event_not_found} ->
        {:error, "Event not found"}

      {:is_owned, nil} ->
        {:error, "User doesn't own actor"}

      {:error, _, %Ecto.Changeset{} = error, _} ->
        {:error, error}
    end
  end

  def update_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to update an event"}
  end

  @doc """
  Delete an event
  """
  def delete_event(
        _parent,
        %{event_id: event_id, actor_id: actor_id},
        %{context: %{current_user: %User{role: role} = user}}
      ) do
    with {:ok, %Event{local: is_local} = event} <- Events.get_event_with_preload(event_id),
         {actor_id, ""} <- Integer.parse(actor_id),
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor_id) do
      cond do
        {:event_can_be_managed, true} == Event.can_be_managed_by(event, actor_id) ->
          do_delete_event(event)

        role in [:moderator, :administrator] ->
          with {:ok, res} <- do_delete_event(event, !is_local),
               %Actor{} = actor <- Actors.get_actor(actor_id) do
            Admin.log_action(actor, "delete", event)

            {:ok, res}
          end

        true ->
          {:error, "You cannot delete this event"}
      end
    else
      {:error, :event_not_found} ->
        {:error, "Event not found"}

      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end

  def delete_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete an event"}
  end

  defp do_delete_event(event, federate \\ true) when is_boolean(federate) do
    with {:ok, _activity, event} <- API.Events.delete_event(event) do
      {:ok, %{id: event.id}}
    end
  end
end
