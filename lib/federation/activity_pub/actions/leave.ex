defmodule Mobilizon.Federation.ActivityPub.Actions.Leave do
  @moduledoc """
  Leave things
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Web.Endpoint
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @spec leave(Event.t(), Actor.t(), boolean, map) ::
          {:ok, Activity.t(), Participant.t()}
          | {:error, :is_only_organizer | :participant_not_found | Ecto.Changeset.t()}
  @spec leave(Actor.t(), Actor.t(), boolean, map) ::
          {:ok, Activity.t(), Member.t()}
          | {:error, :is_not_only_admin | :member_not_found | Ecto.Changeset.t()}
  def leave(object, actor, local \\ true, additional \\ %{})

  @doc """
  Leave an event or a group
  """
  def leave(
        %Event{id: event_id, url: event_url} = _event,
        %Actor{id: actor_id, url: actor_url} = _actor,
        local,
        additional
      ) do
    if Participant.is_not_only_organizer(event_id, actor_id) do
      {:error, :is_only_organizer}
    else
      case Mobilizon.Events.get_participant(
             event_id,
             actor_id,
             Map.get(additional, :metadata, %{})
           ) do
        {:ok, %Participant{} = participant} ->
          case Events.delete_participant(participant) do
            {:ok, %{participant: %Participant{} = participant}} ->
              leave_data = %{
                "type" => "Leave",
                # If it's an exclusion it should be something else
                "actor" => actor_url,
                "object" => event_url,
                "id" => "#{Endpoint.url()}/leave/event/#{participant.id}"
              }

              audience = Audience.get_audience(participant)
              {:ok, activity} = create_activity(Map.merge(leave_data, audience), local)
              maybe_federate(activity)
              {:ok, activity, participant}

            {:error, _type, %Ecto.Changeset{} = err, _} ->
              {:error, err}
          end

        {:error, :participant_not_found} ->
          {:error, :participant_not_found}
      end
    end
  end

  def leave(
        %Actor{type: :Group, id: group_id, url: group_url, members_url: group_members_url},
        %Actor{id: actor_id, url: actor_url},
        local,
        additional
      ) do
    case Actors.get_member(actor_id, group_id) do
      {:ok, %Member{id: member_id} = member} ->
        if Map.get(additional, :force_member_removal, false) ||
             !Actors.is_only_administrator?(member_id, group_id) do
          with {:ok, %Member{} = member} <- Actors.delete_member(member) do
            Mobilizon.Service.Activity.Member.insert_activity(member, subject: "member_quit")

            leave_data = %{
              "to" => [group_members_url],
              "cc" => [group_url],
              "attributedTo" => group_url,
              "type" => "Leave",
              "actor" => actor_url,
              "object" => group_url
            }

            {:ok, activity} = create_activity(leave_data, local)
            maybe_federate(activity)
            maybe_relay_if_group_activity(activity)
            {:ok, activity, member}
          end
        else
          {:error, :is_not_only_admin}
        end

      {:error, :member_not_found} ->
        nil
    end
  end
end
