defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.InviteTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub.Transmogrifier

  describe "handle Invite activities on group" do
    test "it accepts Invite activities" do
      %Actor{url: group_url, id: group_id} = group = insert(:group)
      %Actor{url: group_admin_url, id: group_admin_id} = group_admin = insert(:actor)

      %Member{} =
        _group_admin_member =
        insert(:member, parent: group, actor: group_admin, role: :administrator)

      %Actor{url: invitee_url, id: invitee_id} = _invitee = insert(:actor)

      invite_data =
        File.read!("test/fixtures/mobilizon-invite-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", group_admin_url)
        |> Map.put("object", group_url)
        |> Map.put("target", invitee_url)

      assert {:ok, activity, %Member{}} = Transmogrifier.handle_incoming(invite_data)
      assert %Member{} = member = Actors.get_member_by_url(invite_data["id"])
      assert member.actor.id == invitee_id
      assert member.parent.id == group_id
      assert member.role == :invited
      assert member.invited_by_id == group_admin_id
    end

    test "it refuses Invite activities for " do
      %Actor{url: group_url, id: group_id} = group = insert(:group)
      %Actor{url: group_admin_url, id: group_admin_id} = group_admin = insert(:actor)

      %Member{} =
        _group_admin_member =
        insert(:member, parent: group, actor: group_admin, role: :administrator)

      %Actor{url: invitee_url, id: invitee_id} = _invitee = insert(:actor)

      invite_data =
        File.read!("test/fixtures/mobilizon-invite-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", group_admin_url)
        |> Map.put("object", group_url)
        |> Map.put("target", invitee_url)

      assert {:ok, activity, %Member{}} = Transmogrifier.handle_incoming(invite_data)
      assert %Member{} = member = Actors.get_member_by_url(invite_data["id"])
      assert member.actor.id == invitee_id
      assert member.parent.id == group_id
      assert member.role == :invited
      assert member.invited_by_id == group_admin_id
    end
  end
end
