defmodule MobilizonWeb.Resolvers.Event do
  @moduledoc """
  Handles the event-related GraphQL calls
  """
  alias Mobilizon.Activity
  alias Mobilizon.Addresses
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Media.Picture
  alias Mobilizon.Users.User
  alias MobilizonWeb.Resolvers.Person

  # We limit the max number of events that can be retrieved
  @event_max_limit 100
  @number_of_related_events 3

  def list_events(_parent, %{page: page, limit: limit}, _resolution)
      when limit < @event_max_limit do
    {:ok, Mobilizon.Events.list_events(page, limit)}
  end

  def list_events(_parent, %{page: _page, limit: _limit}, _resolution) do
    {:error, :events_max_limit_reached}
  end

  def find_event(_parent, %{uuid: uuid}, _resolution) do
    case Mobilizon.Events.get_event_full_by_uuid(uuid) do
      nil ->
        {:error, "Event with UUID #{uuid} not found"}

      event ->
        {:ok, Map.put(event, :organizer_actor, Person.proxify_pictures(event.organizer_actor))}
    end
  end

  @doc """
  List participant for event (separate request)
  """
  def list_participants_for_event(_parent, %{uuid: uuid, page: page, limit: limit}, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid, page, limit)}
  end

  @doc """
  List participants for event (through an event request)
  """
  def list_participants_for_event(%Event{uuid: uuid}, _args, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid, 1, 10)}
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
      [Events.get_actor_upcoming_public_event(organizer_actor, uuid)]
      |> Enum.filter(&is_map/1)

    # We find similar events with the same tags
    # uniq_by : It's possible event_from_same_actor is inside events_from_tags
    events =
      (events ++
         Events.find_similar_events_by_common_tags(
           tags,
           @number_of_related_events
         ))
      |> uniq_events()

    # TODO: We should use tag_relations to find more appropriate events

    # We've considered all recommended events, so we fetch the latest events
    events =
      if @number_of_related_events - length(events) > 0 do
        (events ++
           Events.list_events(1, @number_of_related_events, :begins_on, :asc, true, true))
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
  Join an event for an actor
  """
  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {:is_owned, true, actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_full(event_id)},
         {:error, :participant_not_found} <- Mobilizon.Events.get_participant(event_id, actor_id),
         {:ok, _activity, participant} <- MobilizonWeb.API.Participations.join(event, actor),
         participant <-
           Map.put(participant, :event, event)
           |> Map.put(:actor, Person.proxify_pictures(actor)) do
      {:ok, participant}
    else
      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, false} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:error, :event_not_found} ->
        {:error, "Event id not found"}

      {:ok, %Participant{}} ->
        {:error, "You are already a participant of this event"}
    end
  end

  def actor_join_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to join an event"}
  end

  @doc """
  Leave an event for an actor
  """
  def actor_leave_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {:is_owned, true, actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_full(event_id)},
         {:ok, _activity, _participant} <- MobilizonWeb.API.Participations.leave(event, actor) do
      {
        :ok,
        %{
          event: %{
            id: event_id
          },
          actor: %{
            id: actor_id
          }
        }
      }
    else
      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, false} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:only_organizer, true} ->
        {:error, "You can't leave event because you're the only event creator participant"}

      {:error, :participant_not_found} ->
        {:error, "Participant not found"}
    end
  end

  def actor_leave_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to leave an event"}
  end

  @doc """
  Create an event
  """
  def create_event(
        _parent,
        %{organizer_actor_id: organizer_actor_id} = args,
        %{
          context: %{
            current_user: user
          }
        } = _resolution
      ) do
    with {:is_owned, true, organizer_actor} <- User.owns_actor(user, organizer_actor_id),
         {:ok, args} <- save_attached_picture(args),
         {:ok, args} <- save_physical_address(args),
         args_with_organizer <- Map.put(args, :organizer_actor, organizer_actor),
         {
           :ok,
           %Activity{
             data: %{
               "object" => %{"type" => "Event"} = _object
             }
           },
           %Event{} = event
         } <-
           MobilizonWeb.API.Events.create_event(args_with_organizer) do
      {:ok, event}
    else
      {:is_owned, false} ->
        {:error, "Organizer actor id is not owned by the user"}
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
        %{
          context: %{
            current_user: user
          }
        } = _resolution
      ) do
    with {:ok, %Event{} = event} <- Mobilizon.Events.get_event(event_id),
         {:is_owned, true, organizer_actor} <- User.owns_actor(user, event.organizer_actor_id),
         {:ok, args} <- save_attached_picture(args),
         {:ok, args} <- save_physical_address(args),
         {
           :ok,
           %Activity{
             data: %{
               "object" => %{"type" => "Event"} = _object
             }
           },
           %Event{} = event
         } <-
           MobilizonWeb.API.Events.update_event(args) do
      {:ok, event}
    else
      {:error, :event_not_found} ->
        {:error, "Event not found"}
    end
  end

  def update_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to update an event"}
  end

  # If we have an attached picture, just transmit it. It will be handled by
  # Mobilizon.Service.ActivityPub.Utils.make_picture_data/1
  # However, we need to pass it's actor ID
  @spec save_attached_picture(map()) :: {:ok, map()}
  defp save_attached_picture(
         %{
           picture: %{
             picture: %{file: %Plug.Upload{} = _picture} = all_pic
           }
         } = args
       ) do
    {:ok, Map.put(args, :picture, Map.put(all_pic, :actor_id, args.organizer_actor_id))}
  end

  # Otherwise if we use a previously uploaded picture we need to fetch it from database
  @spec save_attached_picture(map()) :: {:ok, map()}
  defp save_attached_picture(
         %{
           picture: %{
             picture_id: picture_id
           }
         } = args
       ) do
    with %Picture{} = picture <- Mobilizon.Media.get_picture(picture_id) do
      {:ok, Map.put(args, :picture, picture)}
    end
  end

  @spec save_attached_picture(map()) :: {:ok, map()}
  defp save_attached_picture(args), do: {:ok, args}

  @spec save_physical_address(map()) :: {:ok, map()}
  defp save_physical_address(
         %{
           physical_address: %{
             url: physical_address_url
           }
         } = args
       )
       when not is_nil(physical_address_url) do
    with %Address{} = address <- Addresses.get_address_by_url(physical_address_url),
         args <- Map.put(args, :physical_address, address.url) do
      {:ok, args}
    end
  end

  @spec save_physical_address(map()) :: {:ok, map()}
  defp save_physical_address(%{physical_address: address} = args) do
    with {:ok, %Address{} = address} <- Addresses.create_address(address),
         args <- Map.put(args, :physical_address, address.url) do
      {:ok, args}
    end
  end

  @spec save_physical_address(map()) :: {:ok, map()}
  defp save_physical_address(args), do: {:ok, args}

  @doc """
  Delete an event
  """
  def delete_event(
        _parent,
        %{event_id: event_id, actor_id: actor_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {:ok, %Event{} = event} <- Mobilizon.Events.get_event(event_id),
         {:is_owned, true, _} <- User.owns_actor(user, actor_id),
         {:event_can_be_managed, true} <- Event.can_event_be_managed_by(event, actor_id),
         event <- Mobilizon.Events.delete_event!(event) do
      {:ok, %{id: event.id}}
    else
      {:error, :event_not_found} ->
        {:error, "Event not found"}

      {:is_owned, false} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:event_can_be_managed, false} ->
        {:error, "You cannot delete this event"}
    end
  end

  def delete_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete an event"}
  end
end
