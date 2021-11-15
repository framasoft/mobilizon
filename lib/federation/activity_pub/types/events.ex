defmodule Mobilizon.Federation.ActivityPub.Types.Events do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events, as: EventsManager
  alias Mobilizon.Events.{Event, Participant, ParticipantRole}
  alias Mobilizon.Federation.ActivityPub.{Actions, Audience, Permission}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Event, as: EventActivity
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Service.LanguageDetection
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Service.Workers.EventDelayedNotificationWorker
  alias Mobilizon.Share
  alias Mobilizon.Tombstone
  import Mobilizon.Events.Utils, only: [calculate_notification_time: 1]
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Event.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def create(args, additional) do
    args = prepare_args_for_event(args)

    case EventsManager.create_event(args) do
      {:ok, %Event{uuid: event_uuid, begins_on: begins_on} = event} ->
        EventActivity.insert_activity(event, subject: "event_created")

        %{action: :notify_of_new_event, event_uuid: event_uuid}
        |> EventDelayedNotificationWorker.new(
          scheduled_at: calculate_notification_time(begins_on)
        )
        |> Oban.insert()

        event_as_data = Convertible.model_to_as(event)
        audience = Audience.get_audience(event)
        create_data = make_create_data(event_as_data, Map.merge(audience, additional))
        {:ok, event, create_data}

      {:error, _step, %Ecto.Changeset{} = err, _} ->
        {:error, err}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec update(Event.t(), map(), map()) ::
          {:ok, Event.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def update(%Event{} = old_event, args, additional) do
    args = prepare_args_for_event(args)

    case EventsManager.update_event(old_event, args) do
      {:ok, %Event{} = new_event} ->
        EventActivity.insert_activity(new_event, subject: "event_updated")
        Cachex.del(:activity_pub, "event_#{new_event.uuid}")
        event_as_data = Convertible.model_to_as(new_event)
        audience = Audience.get_audience(new_event)
        update_data = make_update_data(event_as_data, Map.merge(audience, additional))
        {:ok, new_event, update_data}

      {:error, _step, %Ecto.Changeset{} = err, _} ->
        {:error, err}

      {:error, err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec delete(Event.t(), Actor.t(), boolean, map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Event.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Event{url: url} = event, %Actor{} = actor, _local, _additionnal) do
    activity_data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => %{
        "type" => "Tombstone",
        "id" => url
      },
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"],
      "id" => url <> "/delete"
    }

    audience = Audience.get_audience(event)

    case EventsManager.delete_event(event) do
      {:ok, %Event{} = event} ->
        case Tombstone.create_tombstone(%{uri: event.url, actor_id: actor.id}) do
          {:ok, %Tombstone{} = _tombstone} ->
            EventActivity.insert_activity(event, subject: "event_deleted")
            Cachex.del(:activity_pub, "event_#{event.uuid}")
            Share.delete_all_by_uri(event.url)
            {:ok, Map.merge(activity_data, audience), actor, event}

          {:error, %Ecto.Changeset{} = err} ->
            {:error, err}
        end

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(Event.t()) :: Actor.t() | nil
  def actor(%Event{organizer_actor: %Actor{} = actor}), do: actor

  def actor(%Event{organizer_actor_id: organizer_actor_id}),
    do: Actors.get_actor(organizer_actor_id)

  def actor(_), do: nil

  @spec group_actor(Event.t()) :: Actor.t() | nil
  def group_actor(%Event{attributed_to: %Actor{} = group}), do: group

  def group_actor(%Event{attributed_to_id: attributed_to_id}) when not is_nil(attributed_to_id),
    do: Actors.get_actor(attributed_to_id)

  def group_actor(_), do: nil

  @spec permissions(Event.t()) :: Permission.t()
  def permissions(%Event{draft: draft, attributed_to_id: _attributed_to_id}) do
    %Permission{
      access: if(draft, do: :moderator, else: :member),
      create: :moderator,
      update: :moderator,
      delete: :moderator
    }
  end

  @spec join(Event.t(), Actor.t(), boolean, map) ::
          {:ok, ActivityStreams.t(), Participant.t()}
          | {:accept, any()}
          | {:error, :maximum_attendee_capacity_reached}
  def join(%Event{} = event, %Actor{} = actor, _local, additional) do
    if check_attendee_capacity?(event) do
      role =
        additional
        |> Map.get(:metadata, %{})
        |> Map.get(:role, Mobilizon.Events.get_default_participant_role(event))

      case Mobilizon.Events.create_participant(%{
             role: role,
             event_id: event.id,
             actor_id: actor.id,
             url: Map.get(additional, :url),
             metadata:
               additional
               |> Map.get(:metadata, %{})
               |> Map.update(:message, nil, &String.trim(HTML.strip_tags(&1)))
           }) do
        {:ok, %Participant{} = participant} ->
          join_data = Convertible.model_to_as(participant)
          audience = Audience.get_audience(participant)

          approve_if_default_role_is_participant(
            event,
            Map.merge(join_data, audience),
            participant,
            role
          )

        {:error, _, %Ecto.Changeset{} = err, _} ->
          {:error, err}
      end
    else
      {:error, :maximum_attendee_capacity_reached}
    end
  end

  @spec check_attendee_capacity?(Event.t()) :: boolean
  defp check_attendee_capacity?(%Event{options: options} = event) do
    maximum_attendee_capacity = Map.get(options, :maximum_attendee_capacity) || 0

    maximum_attendee_capacity == 0 ||
      Mobilizon.Events.count_participant_participants(event.id) < maximum_attendee_capacity
  end

  # Set the participant to approved if the default role for new participants is :participant
  @spec approve_if_default_role_is_participant(
          Event.t(),
          ActivityStreams.t(),
          Participant.t(),
          ParticipantRole.t()
        ) :: {:ok, ActivityStreams.t(), Participant.t()} | {:accept, any()}
  defp approve_if_default_role_is_participant(event, activity_data, participant, role) do
    case event do
      %Event{attributed_to: %Actor{id: group_id, url: group_url}} ->
        case Actors.get_single_group_moderator_actor(group_id) do
          %Actor{} = actor ->
            do_approve(event, activity_data, participant, role, %{
              "actor" => actor.url,
              "attributedTo" => group_url
            })

          _ ->
            {:ok, activity_data, participant}
        end

      %Event{attributed_to: nil, local: true} ->
        do_approve(event, activity_data, participant, role, %{
          "actor" => event.organizer_actor.url
        })

      %Event{} ->
        {:ok, activity_data, participant}
    end
  end

  @spec do_approve(Event.t(), ActivityStreams.t(), Particpant.t(), ParticipantRole.t(), map()) ::
          {:accept, any} | {:ok, ActivityStreams.t(), Participant.t()}
  defp do_approve(event, activity_data, participant, role, additionnal) do
    cond do
      Mobilizon.Events.get_default_participant_role(event) == :participant &&
          role == :participant ->
        {:accept,
         Actions.Accept.accept(
           :join,
           participant,
           true,
           additionnal
         )}

      Mobilizon.Events.get_default_participant_role(event) == :not_approved &&
          role == :not_approved ->
        Scheduler.pending_participation_notification(event)
        {:ok, activity_data, participant}

      true ->
        {:ok, activity_data, participant}
    end
  end

  # Prepare and sanitize arguments for events
  @spec prepare_args_for_event(map) :: map
  defp prepare_args_for_event(args) do
    # If title is not set: we are not updating it
    args =
      if Map.has_key?(args, :title) && !is_nil(args.title),
        do: Map.update(args, :title, "", &String.trim/1),
        else: args

    # If we've been given a description (we might not get one if updating)
    # sanitize it, HTML it, and extract tags & mentions from it
    args =
      if Map.has_key?(args, :description) && !is_nil(args.description) do
        {description, mentions, tags} =
          APIUtils.make_content_html(
            String.trim(args.description),
            Map.get(args, :tags, []),
            "text/html"
          )

        mentions = ConverterUtils.fetch_mentions(Map.get(args, :mentions, []) ++ mentions)

        Map.merge(args, %{
          description: description,
          mentions: mentions,
          tags: tags
        })
      else
        args
      end

    # Check that we can only allow anonymous participation if our instance allows it
    {_, options} =
      Map.get_and_update(
        Map.get(args, :options, %{anonymous_participation: false}),
        :anonymous_participation,
        fn value ->
          {value, value && Mobilizon.Config.anonymous_participation?()}
        end
      )

    args
    |> Map.put(:options, options)
    |> Map.put_new(:language, "und")
    |> Map.update!(:language, fn lang ->
      if lang == "und", do: LanguageDetection.detect(:event, args), else: lang
    end)
    |> Map.update(:tags, [], &ConverterUtils.fetch_tags/1)
    |> Map.update(:contacts, [], &ConverterUtils.fetch_actors/1)
  end
end
