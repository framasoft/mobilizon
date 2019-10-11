defmodule MobilizonWeb.Resolvers.Event do
  @moduledoc """
  Handles the event-related GraphQL calls.
  """

  import Mobilizon.Service.Admin.ActionLogService

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Media.Picture
  alias Mobilizon.Service.ActivityPub.Activity
  alias Mobilizon.Users.User

  alias MobilizonWeb.API
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

  defp find_private_event(
         _parent,
         %{uuid: uuid},
         %{context: %{current_user: %User{id: user_id}}} = _resolution
       ) do
    case {:has_event, Mobilizon.Events.get_own_event_by_uuid_with_preload(uuid, user_id)} do
      {:has_event, %Event{} = event} ->
        {:ok, Map.put(event, :organizer_actor, Person.proxify_pictures(event.organizer_actor))}

      {:has_event, _} ->
        {:error, "Event with UUID #{uuid} not found"}
    end
  end

  defp find_private_event(_parent, %{uuid: uuid}, _resolution),
    do: {:error, "Event with UUID #{uuid} not found"}

  def find_event(parent, %{uuid: uuid} = args, resolution) do
    case {:has_event, Mobilizon.Events.get_public_event_by_uuid_with_preload(uuid)} do
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
           {:actor_approve_permission, Mobilizon.Events.moderator_for_event?(event_id, actor_id)} do
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

      {:ok, Mobilizon.Events.list_participants_for_event(event_id, roles, page, limit)}
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

  def stats_participants_for_event(%Event{id: id}, _args, _resolution) do
    {:ok,
     %{
       approved: Mobilizon.Events.count_approved_participants(id),
       unapproved: Mobilizon.Events.count_unapproved_participants(id),
       rejected: Mobilizon.Events.count_rejected_participants(id),
       participants: Mobilizon.Events.count_participant_participants(id),
     }}
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
  Join an event for an actor
  """
  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id},
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_with_preload(event_id)},
         {:error, :participant_not_found} <- Mobilizon.Events.get_participant(event_id, actor_id),
         {:ok, _activity, participant} <- API.Participations.join(event, actor),
         participant <-
           participant
           |> Map.put(:event, event)
           |> Map.put(:actor, Person.proxify_pictures(actor)) do
      {:ok, participant}
    else
      {:maximum_attendee_capacity, _} ->
        {:error, "The event has already reached it's maximum capacity"}

      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, nil} ->
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
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_with_preload(event_id)},
         {:ok, _activity, _participant} <- API.Participations.leave(event, actor) do
      {:ok, %{event: %{id: event_id}, actor: %{id: actor_id}}}
    else
      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, nil} ->
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

  def update_participation(
        _parent,
        %{id: participation_id, moderator_actor_id: moderator_actor_id, role: new_role},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    # Check that moderator provided is rightly authenticated
    with {:is_owned, moderator_actor} <- User.owns_actor(user, moderator_actor_id),
         # Check that participation already exists
         {:has_participation, %Participant{role: old_role} = participation} <-
           {:has_participation, Mobilizon.Events.get_participant(participation_id)},
         {:same_role, false} <- {:same_role, new_role == old_role},
         # Check that moderator has right
         {:actor_approve_permission, true} <-
           {:actor_approve_permission,
            Mobilizon.Events.moderator_for_event?(participation.event.id, moderator_actor_id)},
         {:ok, _activity, participation} <-
           MobilizonWeb.API.Participations.update(participation, moderator_actor, new_role) do
      {:ok, participation}
    else
      {:is_owned, nil} ->
        {:error, "Moderator Actor ID is not owned by authenticated user"}

      {:has_participation, %Participant{role: role, id: id}} ->
        {:error,
         "Participant #{id} can't be approved since it's already a participant (with role #{role})"}

      {:actor_approve_permission, _} ->
        {:error, "Provided moderator actor ID doesn't have permission on this event"}

      {:same_role, true} ->
        {:error, "Participant already has role #{new_role}"}

      {:error, :participant_not_found} ->
        {:error, "Participant not found"}
    end
  end

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
         {:ok, args_with_organizer} <- save_attached_picture(args_with_organizer),
         {:ok, args_with_organizer} <- save_physical_address(args_with_organizer),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           MobilizonWeb.API.Events.create_event(args_with_organizer) do
      {:ok, event}
    else
      {:is_owned, nil} ->
        {:error, "Organizer actor id is not owned by the user"}

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
         {:is_owned, %Actor{} = organizer_actor} <-
           User.owns_actor(user, event.organizer_actor_id),
         args <- Map.put(args, :organizer_actor, organizer_actor),
         {:ok, args} <- save_attached_picture(args),
         {:ok, args} <- save_physical_address(args),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           MobilizonWeb.API.Events.update_event(args, event) do
      {:ok, event}
    else
      {:error, :event_not_found} ->
        {:error, "Event not found"}

      {:is_owned, nil} ->
        {:error, "User doesn't own actor"}
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
         %{picture: %{picture: %{file: %Plug.Upload{} = _picture} = all_pic}} = args
       ) do
    {:ok, Map.put(args, :picture, Map.put(all_pic, :actor_id, args.organizer_actor.id))}
  end

  # Otherwise if we use a previously uploaded picture we need to fetch it from database
  @spec save_attached_picture(map()) :: {:ok, map()}
  defp save_attached_picture(%{picture: %{picture_id: picture_id}} = args) do
    with %Picture{} = picture <- Mobilizon.Media.get_picture(picture_id) do
      {:ok, Map.put(args, :picture, picture)}
    end
  end

  @spec save_attached_picture(map()) :: {:ok, map()}
  defp save_attached_picture(args), do: {:ok, args}

  @spec save_physical_address(map()) :: {:ok, map()}
  defp save_physical_address(%{physical_address: %{url: physical_address_url}} = args)
       when not is_nil(physical_address_url) do
    with %Address{} = address <- Addresses.get_address_by_url(physical_address_url),
         args <- Map.put(args, :physical_address, address.url) do
      {:ok, args}
    end
  end

  @spec save_physical_address(map()) :: {:ok, map()}
  defp save_physical_address(%{physical_address: address} = args) when address != nil do
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
            log_action(actor, "delete", event)

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
    with {:ok, _activity, event} <- MobilizonWeb.API.Events.delete_event(event) do
      {:ok, %{id: event.id}}
    end
  end
end
