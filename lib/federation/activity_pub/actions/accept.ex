defmodule Mobilizon.Federation.ActivityPub.Actions.Accept do
  @moduledoc """
  Accept things
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.Participant
  alias Mobilizon.Federation.ActivityPub.{Audience, Refresher}
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Web.Email.Member, as: EmailMember
  alias Mobilizon.Web.Endpoint
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      make_accept_join_data: 2,
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @type acceptable_types :: :join | :follow | :invite | :member
  @type acceptable_entities ::
          accept_join_entities | accept_follow_entities | accept_invite_entities

  @spec accept(acceptable_types, acceptable_entities, boolean, map) ::
          {:ok, ActivityStream.t(), acceptable_entities} | {:error, Ecto.Changeset.t()}
  def accept(type, entity, local \\ true, additional \\ %{}) do
    Logger.debug("We're accepting something")

    accept_res =
      case type do
        :join -> accept_join(entity, additional)
        :follow -> accept_follow(entity, additional)
        :invite -> accept_invite(entity, additional)
        :member -> accept_member(entity, additional)
      end

    with {:ok, entity, update_data} <- accept_res do
      {:ok, activity} = create_activity(update_data, local)
      maybe_federate(activity)
      maybe_relay_if_group_activity(activity)
      {:ok, activity, entity}
    end
  end

  @type accept_follow_entities :: Follower.t()

  @spec accept_follow(Follower.t(), map) ::
          {:ok, Follower.t(), Activity.t()} | {:error, Ecto.Changeset.t()}
  defp accept_follow(%Follower{} = follower, additional) do
    with {:ok, %Follower{} = follower} <- Actors.update_follower(follower, %{approved: true}) do
      follower_as_data = Convertible.model_to_as(follower)

      update_data =
        make_accept_join_data(
          follower_as_data,
          Map.merge(additional, %{
            "id" => "#{Endpoint.url()}/accept/follow/#{follower.id}",
            "to" => [follower.actor.url],
            "cc" => [],
            "actor" => follower.target_actor.url
          })
        )

      {:ok, follower, update_data}
    end
  end

  @type accept_join_entities :: Participant.t() | Member.t()

  @spec accept_join(Participant.t() | Member.t(), map) ::
          {:ok, Participant.t() | Member.t(), Activity.t()} | {:error, Ecto.Changeset.t()}
  defp accept_join(%Participant{} = participant, additional) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participant, %{role: :participant}) do
      Absinthe.Subscription.publish(Endpoint, participant.actor,
        event_person_participation_changed: participant.actor.id
      )

      Scheduler.trigger_notifications_for_participant(participant)
      participant_as_data = Convertible.model_to_as(participant)
      audience = Audience.get_audience(participant)

      accept_join_data =
        make_accept_join_data(
          participant_as_data,
          Map.merge(Map.merge(audience, additional), %{
            "id" => "#{Endpoint.url()}/accept/join/#{participant.id}"
          })
        )

      {:ok, participant, accept_join_data}
    end
  end

  defp accept_join(%Member{} = member, additional) do
    with {:ok, %Member{} = member} <-
           Actors.update_member(member, %{role: :member}) do
      Mobilizon.Service.Activity.Member.insert_activity(member,
        subject: "member_approved"
      )

      maybe_refresh_group(member)

      Absinthe.Subscription.publish(Endpoint, member.actor,
        group_membership_changed: [
          Actor.preferred_username_and_domain(member.parent),
          member.actor.id
        ]
      )

      member_as_data = Convertible.model_to_as(member)
      audience = Audience.get_audience(member)

      accept_join_data =
        make_accept_join_data(
          member_as_data,
          Map.merge(Map.merge(audience, additional), %{
            "id" => "#{Endpoint.url()}/accept/join/#{member.id}"
          })
        )

      {:ok, member, accept_join_data}
    end
  end

  @type accept_invite_entities :: Member.t()

  @spec accept_invite(Member.t(), map()) ::
          {:ok, Member.t(), Activity.t()} | {:error, Ecto.Changeset.t()}
  defp accept_invite(
         %Member{invited_by_id: invited_by_id, actor_id: actor_id} = member,
         _additional
       ) do
    with %Actor{} = inviter <- Actors.get_actor!(invited_by_id),
         %Actor{url: actor_url} <- Actors.get_actor!(actor_id),
         {:ok, %Member{id: member_id} = member} <-
           Actors.update_member(member, %{role: :member}) do
      Mobilizon.Service.Activity.Member.insert_activity(member,
        subject: "member_accepted_invitation"
      )

      maybe_refresh_group(member)

      accept_data = %{
        "type" => "Accept",
        "attributedTo" => member.parent.url,
        "to" => [inviter.url, member.parent.members_url],
        "cc" => [member.parent.url],
        "actor" => actor_url,
        "object" => Convertible.model_to_as(member),
        "id" => "#{Endpoint.url()}/accept/invite/member/#{member_id}"
      }

      {:ok, member, accept_data}
    end
  end

  @spec accept_member(Member.t(), map()) ::
          {:ok, Member.t(), Activity.t()} | {:error, Ecto.Changeset.t()}
  defp accept_member(
         %Member{actor_id: actor_id, actor: actor, parent: %Actor{} = group} = member,
         %{moderator: %Actor{url: actor_url} = moderator}
       ) do
    with %Actor{} <- Actors.get_actor!(actor_id),
         {:ok, %Member{id: member_id} = member} <-
           Actors.update_member(member, %{role: :member}) do
      Mobilizon.Service.Activity.Member.insert_activity(member,
        subject: "member_approved",
        moderator: moderator
      )

      Absinthe.Subscription.publish(Endpoint, actor,
        group_membership_changed: [Actor.preferred_username_and_domain(group), actor_id]
      )

      EmailMember.send_notification_to_approved_member(member)

      Cachex.del(:activity_pub, "member_#{member_id}")

      maybe_refresh_group(member)

      accept_data = %{
        "type" => "Accept",
        "attributedTo" => member.parent.url,
        "to" => [member.parent.members_url],
        "cc" => [member.parent.url],
        "actor" => actor_url,
        "object" => Convertible.model_to_as(member),
        "id" => "#{Endpoint.url()}/accept/member/#{member_id}"
      }

      {:ok, member, accept_data}
    end
  end

  @spec maybe_refresh_group(Member.t()) :: {:ok, Actor.t()} | {:error, atom()} | {:error}
  defp maybe_refresh_group(%Member{
         parent: %Actor{} = group
       }),
       do: Refresher.refresh_profile(group)
end
