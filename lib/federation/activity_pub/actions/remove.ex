defmodule Mobilizon.Federation.ActivityPub.Actions.Remove do
  @moduledoc """
  Remove things
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Web.Email.Member, as: EmailMember
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @doc """
  Remove an activity, using an activity of type `Remove`
  """
  @spec remove(Member.t(), Actor.t(), Actor.t(), boolean, map) ::
          {:ok, Activity.t(), Member.t()} | {:error, :member_not_found | Ecto.Changeset.t()}
  def remove(
        %Member{id: member_id},
        %Actor{type: :Group, url: group_url, members_url: group_members_url},
        %Actor{url: moderator_url} = moderator,
        local,
        _additional \\ %{}
      ) do
    with %Member{actor: %Actor{url: actor_url}} = member <- Actors.get_member(member_id),
         {:ok, %Member{}} <- Actors.delete_member(member) do
      Mobilizon.Service.Activity.Member.insert_activity(member,
        moderator: moderator,
        subject: "member_removed"
      )

      Cachex.del(:activity_pub, "member_#{member_id}")

      EmailMember.send_notification_to_removed_member(member)

      remove_data = %{
        "to" => [actor_url, group_members_url],
        "type" => "Remove",
        "actor" => moderator_url,
        "object" => member.url,
        "origin" => group_url
      }

      {:ok, activity} = create_activity(remove_data, local)
      maybe_federate(activity)
      maybe_relay_if_group_activity(activity)
      {:ok, activity, member}
    else
      nil -> {:error, :member_not_found}
      {:error, %Ecto.Changeset{} = err} -> {:error, err}
    end
  end
end
