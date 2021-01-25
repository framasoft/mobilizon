defmodule Mobilizon.GraphQL.Resolvers.Event do
  @moduledoc """
  Handles the event-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.{Event, EventParticipantStats}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.API

  alias Mobilizon.Federation.ActivityPub.Activity
  import Mobilizon.Users.Guards, only: [is_moderator: 1]
  import Mobilizon.Web.Gettext

  # We limit the max number of events that can be retrieved
  @event_max_limit 100
  @number_of_related_events 3

  def organizer_for_event(
        %Event{attributed_to_id: attributed_to_id, organizer_actor_id: organizer_actor_id},
        _args,
        %{context: %{current_user: %User{role: user_role} = user}} = _resolution
      )
      when not is_nil(attributed_to_id) do
    with %Actor{id: group_id} <- Actors.get_actor(attributed_to_id),
         %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <-
           {:member, Actors.is_member?(actor_id, group_id) or is_moderator(user_role)},
         %Actor{} = actor <- Actors.get_actor(organizer_actor_id) do
      {:ok, actor}
    else
      _ -> {:ok, nil}
    end
  end

  def organizer_for_event(
        %Event{attributed_to_id: attributed_to_id},
        _args,
        _resolution
      )
      when not is_nil(attributed_to_id) do
    case Actors.get_actor(attributed_to_id) do
      %Actor{} -> {:ok, nil}
      _ -> {:error, "Unable to get organizer actor"}
    end
  end

  def organizer_for_event(
        %Event{organizer_actor_id: organizer_actor_id},
        _args,
        _resolution
      ) do
    case Actors.get_actor(organizer_actor_id) do
      %Actor{} = actor -> {:ok, actor}
      _ -> {:error, "Unable to get organizer actor"}
    end
  end

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
        {:ok, event}

      {:has_event, _} ->
        {:error, :event_not_found}
    end
  end

  defp find_private_event(_parent, _args, _resolution) do
    {:error, :event_not_found}
  end

  def find_event(parent, %{uuid: uuid} = args, %{context: context} = resolution) do
    with {:has_event, %Event{} = event} <-
           {:has_event, Events.get_public_event_by_uuid_with_preload(uuid)},
         {:access_valid, true} <-
           {:access_valid, Map.has_key?(context, :current_user) || check_event_access(event)} do
      {:ok, event}
    else
      {:has_event, _} ->
        find_private_event(parent, args, resolution)

      {:access_valid, _} ->
        {:error, :event_not_found}
    end
  end

  @spec check_event_access(Event.t()) :: boolean()
  defp check_event_access(%Event{local: true}), do: true

  defp check_event_access(%Event{url: url}) do
    relay_actor_id = Config.relay_actor_id()
    Events.check_if_event_has_instance_follow(url, relay_actor_id)
  end

  @doc """
  List participants for event (through an event request)
  """
  def list_participants_for_event(
        %Event{id: event_id},
        %{page: page, limit: limit, roles: roles},
        %{context: %{current_user: %User{} = user}} = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
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

      participants = Events.list_participants_for_event(event_id, roles, page, limit)
      {:ok, participants}
    else
      {:actor_approve_permission, _} ->
        {:error,
         dgettext("errors", "Provided moderator profile doesn't have permission on this event")}
    end
  end

  def list_participants_for_event(_, _args, _resolution) do
    {:ok, %{total: 0, elements: []}}
  end

  def stats_participants(
        %Event{participant_stats: %EventParticipantStats{} = stats, id: event_id} = _event,
        _args,
        %{context: %{current_user: %User{id: user_id} = _user}} = _resolution
      ) do
    if Events.is_user_moderator_for_event?(user_id, event_id) do
      {:ok,
       Map.put(
         stats,
         :going,
         stats.participant + stats.moderator + stats.administrator + stats.creator
       )}
    else
      {:ok, %{participant: stats.participant}}
    end
  end

  def stats_participants(
        %Event{participant_stats: %EventParticipantStats{participant: participant}},
        _args,
        _resolution
      ) do
    {:ok, %EventParticipantStats{participant: participant}}
  end

  def stats_participants(_event, _args, _resolution) do
    {:ok, %EventParticipantStats{}}
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
          Events.list_events(1, @number_of_related_events, :begins_on, :asc, true).elements
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
    with {:is_owned, %Actor{} = organizer_actor} <- User.owns_actor(user, organizer_actor_id),
         args <- Map.put(args, :options, args[:options] || %{}),
         args_with_organizer <- Map.put(args, :organizer_actor, organizer_actor),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.create_event(args_with_organizer) do
      {:ok, event}
    else
      {:is_owned, nil} ->
        {:error, dgettext("errors", "Organizer profile is not owned by the user")}

      {:error, _, %Ecto.Changeset{} = error, _} ->
        {:error, error}

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}
    end
  end

  def create_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to create events")}
  end

  @doc """
  Update an event
  """
  def update_event(
        _parent,
        %{event_id: event_id} = args,
        %{context: %{current_user: %User{} = user}} = _resolution
      ) do
    # See https://github.com/absinthe-graphql/absinthe/issues/490
    with args <- Map.put(args, :options, args[:options] || %{}),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:old_actor, {:is_owned, %Actor{}}} <-
           {:old_actor, User.owns_actor(user, event.organizer_actor_id)},
         new_organizer_actor_id <- args |> Map.get(:organizer_actor_id, event.organizer_actor_id),
         {:new_actor, {:is_owned, %Actor{} = organizer_actor}} <-
           {:new_actor, User.owns_actor(user, new_organizer_actor_id)},
         args <- Map.put(args, :organizer_actor, organizer_actor),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.update_event(args, event) do
      {:ok, event}
    else
      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event not found")}

      {:old_actor, _} ->
        {:error, dgettext("errors", "You can't edit this event.")}

      {:new_actor, _} ->
        {:error, dgettext("errors", "You can't attribute this event to this profile.")}

      {:error, _, %Ecto.Changeset{} = error, _} ->
        {:error, error}
    end
  end

  def update_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update an event")}
  end

  @doc """
  Delete an event
  """
  def delete_event(
        _parent,
        %{event_id: event_id},
        %{context: %{current_user: %User{role: role} = user}}
      ) do
    with {:ok, %Event{local: is_local} = event} <- Events.get_event_with_preload(event_id),
         %Actor{id: actor_id} = actor <- Users.get_actor_for_user(user) do
      cond do
        {:event_can_be_managed, true} == Event.can_be_managed_by(event, actor_id) ->
          do_delete_event(event, actor)

        role in [:moderator, :administrator] ->
          with {:ok, res} <- do_delete_event(event, actor, !is_local),
               %Actor{} = actor <- Actors.get_actor(actor_id) do
            Admin.log_action(actor, "delete", event)

            {:ok, res}
          end

        true ->
          {:error, dgettext("errors", "You cannot delete this event")}
      end
    else
      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event not found")}
    end
  end

  def delete_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to delete an event")}
  end

  defp do_delete_event(%Event{} = event, %Actor{} = actor, federate \\ true)
       when is_boolean(federate) do
    with {:ok, _activity, event} <- API.Events.delete_event(event, actor) do
      {:ok, %{id: event.id}}
    end
  end
end
