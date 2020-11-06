defmodule Mobilizon.GraphQL.Resolvers.MemberTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Member
  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Member Resolver to join a group" do
    @join_group_mutation """
    mutation JoinGroup($groupId: ID!) {
      joinGroup(groupId: $groupId) {
        id
        role,
        actor {
          id
        },
        parent {
          id
        }
      }
    }
    """

    test "join_group/3 should create a member", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @join_group_mutation,
          variables: %{groupId: group.id}
        )

      assert res["errors"] == nil
      assert res["data"]["joinGroup"]["role"] == "NOT_APPROVED"
      assert res["data"]["joinGroup"]["parent"]["id"] == to_string(group.id)
      assert res["data"]["joinGroup"]["actor"]["id"] == to_string(actor.id)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @join_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "already a member"
    end

    test "join_group/3 should check the group is not invite only", %{
      conn: conn,
      user: user
    } do
      group = insert(:group, %{openness: :invite_only})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @join_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "cannot join this group"
    end

    test "join_group/3 should check the group exists", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @join_group_mutation,
          variables: %{groupId: 1042}
        )

      assert hd(res["errors"])["message"] =~ "Group not found"
    end
  end

  describe "Member Resolver to leave from a group" do
    @leave_group_mutation """
    mutation LeaveGroup($groupId: ID!) {
      leaveGroup(groupId: $groupId) {
        id
      }
    }
    """

    test "leave_group/3 should delete a member from a group", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, role: :administrator, parent: group)
      %Member{id: member_id} = insert(:member, %{actor: actor, parent: group})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @leave_group_mutation,
          variables: %{groupId: group.id}
        )

      assert res["errors"] == nil
      assert res["data"]["leaveGroup"]["id"] == to_string(member_id)
    end

    test "leave_group/3 should check if the member is the only administrator", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, role: :creator, parent: group})
      insert(:member, %{parent: group})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @leave_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "only administrator"
    end

    test "leave_group/3 should check the user is logged in", %{conn: conn, actor: actor} do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @leave_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "logged-in"
    end

    test "leave_group/3 should check the group exists", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @leave_group_mutation,
          variables: %{groupId: 1042}
        )

      assert hd(res["errors"])["message"] =~ "Group not found"
    end
  end

  describe "Member Resolver to invite to a group" do
    @invite_member_mutation """
      mutation InviteMember($groupId: ID!, $targetActorUsername: String!) {
        inviteMember(groupId: $groupId, targetActorUsername: $targetActorUsername) {
          parent {
            id
          },
          actor {
            id
          },
          role
        }
      }
    """

    setup %{conn: conn, actor: actor, user: user} do
      group = insert(:group)
      target_actor = insert(:actor, user: user)

      {:ok, conn: conn, actor: actor, user: user, group: group, target_actor: target_actor}
    end

    test "invite_member/3 invites a local actor to a group", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group,
      target_actor: target_actor
    } do
      _admin_member = insert(:member, %{actor: actor, parent: group, role: :creator})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: target_actor.preferred_username
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["inviteMember"]["role"] == "INVITED"
      assert res["data"]["inviteMember"]["parent"]["id"] == to_string(group.id)
      assert res["data"]["inviteMember"]["actor"]["id"] == to_string(target_actor.id)
    end

    test "invite_member/3 invites a remote actor to a group", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      _admin_member = insert(:member, %{actor: actor, parent: group, role: :creator})
      target_actor = insert(:actor, domain: "remote.tld")

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: "#{target_actor.preferred_username}@#{target_actor.domain}"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["inviteMember"]["role"] == "INVITED"
      assert res["data"]["inviteMember"]["parent"]["id"] == to_string(group.id)
      assert res["data"]["inviteMember"]["actor"]["id"] == to_string(target_actor.id)
    end

    test "invite_member/3 fails to invite a local actor to a group that invitor isn't in", %{
      conn: conn,
      user: user,
      group: group,
      target_actor: target_actor
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: target_actor.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "You are not a member of this group"
    end

    test "invite_member/3 fails to invite a non existing local actor", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      insert(:member, %{actor: actor, parent: group, role: :administrator})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: "not_existing"
          }
        )

      assert hd(res["errors"])["message"] == "Profile invited doesn't exist"
    end

    test "invite_member/3 fails to invite a non existing remote actor", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      insert(:member, %{actor: actor, parent: group, role: :administrator})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: "not_existing@nowhere.absolute"
          }
        )

      assert hd(res["errors"])["message"] == "Profile invited doesn't exist"
    end

    test "invite_member/3 fails to invite a actor for a non-existing group", %{
      conn: conn,
      user: user,
      target_actor: target_actor
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: "780907988778",
            targetActorUsername: target_actor.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "Group not found"
    end

    test "invite_member/3 fails to invite a actor if we are not an admin for the group", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group,
      target_actor: target_actor
    } do
      _admin_member = insert(:member, %{actor: actor, parent: group, role: :member})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: target_actor.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "You cannot invite to this group"
    end

    test "invite_member/3 fails to invite a actor if it's already a member of the group", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group,
      target_actor: target_actor
    } do
      insert(:member, %{actor: actor, parent: group, role: :member})
      insert(:member, %{actor: target_actor, parent: group, role: :member})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @invite_member_mutation,
          variables: %{
            groupId: group.id,
            targetActorUsername: target_actor.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "You cannot invite to this group"
    end
  end

  describe "Member resolver to update a group member" do
    @update_member_mutation """
      mutation UpdateMember($memberId: ID!, $role: MemberRoleEnum!) {
        updateMember(memberId: $memberId, role: $role) {
          id
          role
        }
      }
    """

    setup %{conn: conn, actor: actor, user: user} do
      group = insert(:group)
      target_actor = insert(:actor, user: user)

      {:ok, conn: conn, actor: actor, user: user, group: group, target_actor: target_actor}
    end

    test "update_member/3 fails when not connected", %{
      conn: conn,
      group: group,
      target_actor: target_actor
    } do
      %Member{id: member_id} =
        insert(:member, %{actor: target_actor, parent: group, role: :member})

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "MODERATOR"
          }
        )

      assert hd(res["errors"])["message"] == "You must be logged-in to update a member"
    end

    test "update_member/3 fails when not a member of the group", %{
      conn: conn,
      group: group,
      target_actor: target_actor
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)
      Mobilizon.Users.update_user_default_actor(user.id, actor.id)

      %Member{id: member_id} =
        insert(:member, %{actor: target_actor, parent: group, role: :member})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "MODERATOR"
          }
        )

      assert hd(res["errors"])["message"] == "You are not a moderator or admin for this group"
    end

    test "update_member/3 updates the member role", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group,
      target_actor: target_actor
    } do
      Mobilizon.Users.update_user_default_actor(user.id, actor.id)
      insert(:member, actor: actor, parent: group, role: :administrator)

      %Member{id: member_id} =
        insert(:member, %{actor: target_actor, parent: group, role: :member})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "MODERATOR"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["updateMember"]["role"] == "MODERATOR"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "ADMINISTRATOR"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["updateMember"]["role"] == "ADMINISTRATOR"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "MEMBER"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["updateMember"]["role"] == "MEMBER"
    end

    test "update_member/3 prevents to downgrade the member role if there's no admin left", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      Mobilizon.Users.update_user_default_actor(user.id, actor.id)
      %Member{id: member_id} = insert(:member, actor: actor, parent: group, role: :administrator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_member_mutation,
          variables: %{
            memberId: member_id,
            role: "MEMBER"
          }
        )

      assert hd(res["errors"])["message"] ==
               "You can't set yourself to a lower member role for this group because you are the only administrator"
    end
  end

  describe "Member resolver to remove a member from a group" do
    # TODO write tests for me plz
  end
end
