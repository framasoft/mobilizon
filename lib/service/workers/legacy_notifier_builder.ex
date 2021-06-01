defmodule Mobilizon.Service.Workers.LegacyNotifierBuilder do
  @moduledoc """
  Worker to push legacy notifications
  """

  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Service.Notifier

  use Mobilizon.Service.Workers.Helper, queue: "activity"

  @impl Oban.Worker
  def perform(%Job{args: args}) do
    with {"legacy_notify", args} <- Map.pop(args, "op") do
      activity = build_activity(args)

      args
      |> users_to_notify(args["author_id"])
      |> Enum.each(&Notifier.notify(&1, activity, single_activity: true))
    end
  end

  def build_activity(args) do
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

  @spec users_to_notify(map(), integer() | String.t()) :: list(Users.t())
  defp users_to_notify(
         %{"subject" => "event_comment_mention", "mentions" => mentionned_actor_ids},
         author_id
       ) do
    users_from_actor_ids(mentionned_actor_ids, author_id)
  end

  defp users_to_notify(
         %{
           "subject" => "participation_event_comment",
           "subject_params" => subject_params
         },
         author_id
       ) do
    subject_params
    |> Map.get("event_id")
    |> Events.list_actors_participants_for_event()
    |> Enum.map(& &1.id)
    |> users_from_actor_ids(author_id)
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
    |> Enum.map(&Users.get_user_with_settings!/1)
  end
end
