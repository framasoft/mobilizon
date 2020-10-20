defmodule Mobilizon.Federation.ActivityPub.Types.Events do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events, as: EventsManager
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Share
  alias Mobilizon.Tombstone
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(args, additional) do
    with args <- prepare_args_for_event(args),
         {:ok, %Event{} = event} <- EventsManager.create_event(args),
         event_as_data <- Convertible.model_to_as(event),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(event),
         create_data <-
           make_create_data(event_as_data, Map.merge(audience, additional)) do
      {:ok, event, create_data}
    end
  end

  @impl Entity
  @spec update(Event.t(), map(), map()) :: {:ok, Event.t(), Activity.t()} | any()
  def update(%Event{} = old_event, args, additional) do
    with args <- prepare_args_for_event(args),
         {:ok, %Event{} = new_event} <- EventsManager.update_event(old_event, args),
         {:ok, true} <- Cachex.del(:activity_pub, "event_#{new_event.uuid}"),
         event_as_data <- Convertible.model_to_as(new_event),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_event),
         update_data <- make_update_data(event_as_data, Map.merge(audience, additional)) do
      {:ok, new_event, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  @spec delete(Event.t(), Actor.t(), boolean, map()) :: {:ok, Event.t()}
  def delete(%Event{url: url} = event, %Actor{} = actor, _local, _additionnal) do
    activity_data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => Convertible.model_to_as(event),
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"],
      "id" => url <> "/delete"
    }

    with audience <-
           Audience.calculate_to_and_cc_from_mentions(event),
         {:ok, %Event{} = event} <- EventsManager.delete_event(event),
         {:ok, true} <- Cachex.del(:activity_pub, "event_#{event.uuid}"),
         {:ok, %Tombstone{} = _tombstone} <-
           Tombstone.create_tombstone(%{uri: event.url, actor_id: actor.id}) do
      Share.delete_all_by_uri(event.url)
      {:ok, Map.merge(activity_data, audience), actor, event}
    end
  end

  def actor(%Event{organizer_actor: %Actor{} = actor}), do: actor

  def actor(%Event{organizer_actor_id: organizer_actor_id}),
    do: Actors.get_actor(organizer_actor_id)

  def actor(_), do: nil

  def group_actor(%Event{attributed_to: %Actor{} = group}), do: group

  def group_actor(%Event{attributed_to_id: attributed_to_id}) when not is_nil(attributed_to_id),
    do: Actors.get_actor(attributed_to_id)

  def group_actor(_), do: nil

  def role_needed_to_update(%Event{attributed_to: %Actor{} = _group}), do: :moderator
  def role_needed_to_delete(%Event{attributed_to_id: _attributed_to_id}), do: :moderator
  def role_needed_to_delete(_), do: nil

  def join(%Event{} = event, %Actor{} = actor, _local, additional) do
    with {:maximum_attendee_capacity, true} <-
           {:maximum_attendee_capacity, check_attendee_capacity(event)},
         role <-
           additional
           |> Map.get(:metadata, %{})
           |> Map.get(:role, Mobilizon.Events.get_default_participant_role(event)),
         {:ok, %Participant{} = participant} <-
           Mobilizon.Events.create_participant(%{
             role: role,
             event_id: event.id,
             actor_id: actor.id,
             url: Map.get(additional, :url),
             metadata:
               additional
               |> Map.get(:metadata, %{})
               |> Map.update(:message, nil, &String.trim(HTML.strip_tags(&1)))
           }),
         join_data <- Convertible.model_to_as(participant),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(participant) do
      approve_if_default_role_is_participant(
        event,
        Map.merge(join_data, audience),
        participant,
        role
      )
    else
      {:maximum_attendee_capacity, err} ->
        {:maximum_attendee_capacity, err}
    end
  end

  defp check_attendee_capacity(%Event{options: options} = event) do
    with maximum_attendee_capacity <-
           Map.get(options, :maximum_attendee_capacity) || 0 do
      maximum_attendee_capacity == 0 ||
        Mobilizon.Events.count_participant_participants(event.id) < maximum_attendee_capacity
    end
  end

  # Set the participant to approved if the default role for new participants is :participant
  defp approve_if_default_role_is_participant(event, activity_data, participant, role) do
    if event.local do
      cond do
        Mobilizon.Events.get_default_participant_role(event) === :participant &&
            role == :participant ->
          {:accept,
           ActivityPub.accept(
             :join,
             participant,
             true,
             %{"actor" => event.organizer_actor.url}
           )}

        Mobilizon.Events.get_default_participant_role(event) === :not_approved &&
            role == :not_approved ->
          Scheduler.pending_participation_notification(event)
          {:ok, activity_data, participant}

        true ->
          {:ok, activity_data, participant}
      end
    else
      {:ok, activity_data, participant}
    end
  end

  # Prepare and sanitize arguments for events
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
    |> Map.update(:tags, [], &ConverterUtils.fetch_tags/1)
    |> Map.update(:contacts, [], &ConverterUtils.fetch_actors/1)
  end
end
