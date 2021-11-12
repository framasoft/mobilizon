defmodule Mobilizon.Federation.ActivityPub.Actions.Reject do
  @moduledoc """
  Reject things
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.Participant
  alias Mobilizon.Federation.ActivityPub.Actions.Accept
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Web.Endpoint
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @spec reject(Accept.acceptable_types(), Accept.acceptable_entities(), boolean, map) ::
          {:ok, ActivityStream.t(), Accept.acceptable_entities()}
  def reject(type, entity, local \\ true, additional \\ %{}) do
    {:ok, entity, update_data} =
      case type do
        :join -> reject_join(entity, additional)
        :follow -> reject_follow(entity, additional)
        :invite -> reject_invite(entity, additional)
        :member -> reject_member(entity, additional)
      end

    {:ok, activity} = create_activity(update_data, local)
    maybe_federate(activity)
    maybe_relay_if_group_activity(activity)
    {:ok, activity, entity}
  end

  @spec reject_join(Participant.t(), map()) :: {:ok, Participant.t(), Activity.t()} | any()
  defp reject_join(%Participant{} = participant, additional) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participant, %{role: :rejected}),
         Absinthe.Subscription.publish(Endpoint, participant.actor,
           event_person_participation_changed: participant.actor.id
         ),
         participant_as_data <- Convertible.model_to_as(participant),
         audience <-
           participant
           |> Audience.get_audience()
           |> Map.merge(additional),
         reject_data <- %{
           "type" => "Reject",
           "object" => participant_as_data
         },
         update_data <-
           reject_data
           |> Map.merge(audience)
           |> Map.merge(%{
             "id" => "#{Endpoint.url()}/reject/join/#{participant.id}"
           }) do
      {:ok, participant, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec reject_follow(Follower.t(), map()) :: {:ok, Follower.t(), Activity.t()} | any()
  defp reject_follow(%Follower{} = follower, additional) do
    with {:ok, %Follower{} = follower} <- Actors.delete_follower(follower),
         follower_as_data <- Convertible.model_to_as(follower),
         audience <-
           follower.actor |> Audience.get_audience() |> Map.merge(additional),
         reject_data <- %{
           "to" => [follower.actor.url],
           "type" => "Reject",
           "actor" => follower.target_actor.url,
           "object" => follower_as_data
         },
         update_data <-
           audience
           |> Map.merge(reject_data)
           |> Map.merge(%{
             "id" => "#{Endpoint.url()}/reject/follow/#{follower.id}"
           }) do
      {:ok, follower, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec reject_invite(Member.t(), map()) :: {:ok, Member.t(), Activity.t()} | any
  defp reject_invite(
         %Member{invited_by_id: invited_by_id, actor_id: actor_id} = member,
         _additional
       ) do
    with %Actor{} = inviter <- Actors.get_actor(invited_by_id),
         %Actor{url: actor_url} <- Actors.get_actor(actor_id),
         {:ok, %Member{url: member_url, id: member_id} = member} <-
           Actors.delete_member(member),
         Mobilizon.Service.Activity.Member.insert_activity(member,
           subject: "member_rejected_invitation"
         ),
         accept_data <- %{
           "type" => "Reject",
           "actor" => actor_url,
           "attributedTo" => member.parent.url,
           "to" => [inviter.url, member.parent.members_url],
           "cc" => [member.parent.url],
           "object" => member_url,
           "id" => "#{Endpoint.url()}/reject/invite/member/#{member_id}"
         } do
      {:ok, member, accept_data}
    end
  end

  @spec reject_member(Member.t(), map()) :: {:ok, Member.t(), Activity.t()} | any
  defp reject_member(
         %Member{actor_id: actor_id} = member,
         %{moderator: %Actor{url: actor_url}}
       ) do
    with %Actor{} <- Actors.get_actor(actor_id),
         {:ok, %Member{url: member_url, id: member_id} = member} <-
           Actors.delete_member(member),
         Mobilizon.Service.Activity.Member.insert_activity(member,
           subject: "member_rejected"
         ),
         accept_data <- %{
           "type" => "Reject",
           "actor" => actor_url,
           "attributedTo" => member.parent.url,
           "to" => [member.parent.members_url],
           "cc" => [member.parent.url],
           "object" => member_url,
           "id" => "#{Endpoint.url()}/reject/member/#{member_id}"
         } do
      {:ok, member, accept_data}
    end
  end
end
