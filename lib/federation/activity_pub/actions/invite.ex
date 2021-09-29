defmodule Mobilizon.Federation.ActivityPub.Actions.Invite do
  @moduledoc """
  Invite people to things
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Web.Email.Group
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @spec invite(Actor.t(), Actor.t(), Actor.t(), boolean, map()) ::
          {:ok, map(), Member.t()} | {:error, :not_able_to_invite | Ecto.Changeset.t()}
  def invite(
        %Actor{url: group_url, id: group_id, members_url: members_url} = group,
        %Actor{url: actor_url, id: actor_id} = actor,
        %Actor{url: target_actor_url, id: target_actor_id} = _target_actor,
        local \\ true,
        additional \\ %{}
      ) do
    Logger.debug("Handling #{actor_url} invite to #{group_url} sent to #{target_actor_url}")

    if is_able_to_invite?(actor, group) do
      with {:ok, %Member{url: member_url} = member} <-
             Actors.create_member(%{
               parent_id: group_id,
               actor_id: target_actor_id,
               role: :invited,
               invited_by_id: actor_id,
               url: Map.get(additional, :url)
             }) do
        Mobilizon.Service.Activity.Member.insert_activity(member,
          moderator: actor,
          subject: "member_invited"
        )

        {:ok, activity} =
          create_activity(
            %{
              "type" => "Invite",
              "attributedTo" => group_url,
              "actor" => actor_url,
              "object" => group_url,
              "target" => target_actor_url,
              "id" => member_url
            }
            |> Map.merge(%{"to" => [target_actor_url, members_url], "cc" => [group_url]})
            |> Map.merge(additional),
            local
          )

        maybe_federate(activity)
        maybe_relay_if_group_activity(activity)
        Group.send_invite_to_user(member)
        {:ok, activity, member}
      end
    else
      {:error, :not_able_to_invite}
    end
  end

  @spec is_able_to_invite?(Actor.t(), Actor.t()) :: boolean
  defp is_able_to_invite?(%Actor{domain: actor_domain, id: actor_id}, %Actor{
         domain: group_domain,
         id: group_id
       }) do
    # If the actor comes from the same domain we trust it
    if actor_domain == group_domain do
      true
    else
      # If local group, we'll send the invite
      case Actors.get_member(actor_id, group_id) do
        {:ok, %Member{} = admin_member} ->
          Member.is_administrator(admin_member)

        _ ->
          false
      end
    end
  end
end
