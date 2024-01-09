defmodule Mobilizon.Service.Workers.LegacyNotifierBuilder do
  @moduledoc """
  Worker to push legacy notifications
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Actors, Config, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Notifier
  require Logger

  use Mobilizon.Service.Workers.Helper, queue: "activity"

  @impl Oban.Worker
  def perform(%Job{args: %{"op" => "legacy_notify"} = args}) do
    {"legacy_notify", args} = Map.pop(args, "op")
    activity = build_activity(args)
    Logger.debug("Handling activity #{activity.subject} to notify in LegacyNotifierBuilder")

    if args["subject"] in ["participation_event_comment", "conversation_created"] do
      special_handling(args["subject"], args, activity)
      :ok
    else
      args
      |> users_to_notify(author_id: args["author_id"], group_id: Map.get(args, "group_id"))
      |> Enum.each(&notify_user(&1, activity))
    end
  end

  defp special_handling("participation_event_comment", args, activity) do
    notify_participants(
      get_in(args, ["subject_params", "event_id"]),
      activity,
      args["author_id"]
    )
  end

  defp special_handling("conversation_created", args, activity) do
    notify_participant(
      get_in(args, ["subject_params", "conversation_event_id"]),
      activity,
      get_in(args, ["participant", "actor_id"]),
      args["author_id"]
    )
  end

  defp build_activity(args) do
    author = Actors.get_actor(args["author_id"])

    %Activity{
      type: String.to_existing_atom(args["type"]),
      subject: String.to_existing_atom(args["subject"]),
      subject_params: args["subject_params"],
      inserted_at: DateTime.utc_now(),
      object_type: String.to_existing_atom(args["object_type"]),
      object_id: args["object_id"],
      group: nil,
      author: author
    }
  end

  @spec users_to_notify(map(), Keyword.t()) :: list(Users.t())
  defp users_to_notify(
         %{"subject" => "event_comment_mention", "mentions" => mentionned_actor_ids},
         options
       ) do
    users_from_actor_ids(mentionned_actor_ids, Keyword.fetch!(options, :author_id))
  end

  @spec users_to_notify(map(), Keyword.t()) :: list(Users.t())
  defp users_to_notify(
         %{"subject" => subject, "participant" => %{"actor_id" => actor_id}},
         options
       )
       when subject in ["conversation_created", "conversation_replied"] do
    users_from_actor_ids([actor_id], Keyword.fetch!(options, :author_id))
  end

  defp users_to_notify(
         %{"subject" => "discussion_mention", "mentions" => mentionned_actor_ids},
         options
       ) do
    mentionned_actor_ids
    |> Enum.filter(&Actors.member?(&1, Keyword.fetch!(options, :group_id)))
    |> users_from_actor_ids(Keyword.fetch!(options, :author_id))
  end

  defp users_to_notify(
         %{
           "subject" => "participation_event_comment",
           "subject_params" => subject_params
         },
         options
       ) do
    subject_params
    |> Map.get("event_id")
    |> Events.list_actors_participants_for_event()
    |> Enum.map(& &1.id)
    |> users_from_actor_ids(Keyword.fetch!(options, :author_id))
  end

  defp users_to_notify(
         %{"subject" => "event_new_comment", "subject_params" => %{"event_uuid" => event_uuid}},
         options
       ) do
    event_uuid
    |> Events.get_event_by_uuid_with_preload()
    |> organizer_actor_id()
    |> users_from_actor_ids(Keyword.fetch!(options, :author_id))
  end

  defp users_to_notify(_, _), do: []

  defp organizer_actor_id(%Event{organizer_actor: %Actor{id: actor_id}}) do
    [actor_id]
  end

  @spec users_from_actor_ids(list(), integer() | String.t()) :: list(Users.t())
  defp users_from_actor_ids(actor_ids, author_id) do
    actor_ids
    |> Enum.filter(&(&1 != author_id))
    |> Enum.map(&Actors.get_actor/1)
    |> Enum.filter(& &1)
    |> Enum.map(& &1.user_id)
    |> Enum.filter(& &1)
    |> Enum.uniq()
    |> Enum.map(&Users.get_user_with_activity_settings!/1)
  end

  defp notify_participants(nil, _activity, _author_id), do: :ok

  defp notify_participants(event_id, activity, author_id) do
    event_id
    |> Events.list_actors_participants_for_event()
    |> Enum.map(& &1.id)
    |> users_from_actor_ids(author_id)
    |> Enum.each(fn user ->
      Notifier.Email.send_anonymous_activity(user.email, activity,
        locale: Map.get(user, :locale, "en")
      )
    end)

    notify_anonymous_participants(event_id, activity)
  end

  defp notify_participant(nil, _activity, _conversation_participant_actor_id, _author_id),
    do: :ok

  defp notify_participant(event_id, activity, conversation_participant_actor_id, author_id) do
    # Anonymous participation
    if conversation_participant_actor_id == Config.anonymous_actor_id() do
      notify_anonymous_participants(event_id, activity)
    else
      [conversation_participant_actor_id]
      |> users_from_actor_ids(author_id)
      |> Enum.each(fn user ->
        Notifier.Email.send_anonymous_activity(user.email, activity,
          locale: Map.get(user, :locale, "en")
        )
      end)
    end
  end

  defp notify_anonymous_participants(nil, _activity), do: :ok

  defp notify_anonymous_participants(event_id, activity) do
    event_id
    |> Events.list_anonymous_participants_for_event()
    |> Enum.filter(fn %Participant{metadata: metadata} ->
      is_map(metadata) && is_binary(metadata.email)
    end)
    |> Enum.map(fn %Participant{metadata: metadata} -> metadata end)
    |> Enum.map(fn %{email: email} = metadata ->
      Notifier.Email.send_anonymous_activity(email, activity,
        locale: Map.get(metadata, :locale, "en") || "en"
      )
    end)
  end

  defp notify_user(user, activity) do
    Logger.debug("Notifying #{user.email} for activity #{activity.subject}")
    Notifier.notify(user, activity, single_activity: true)
  end
end
