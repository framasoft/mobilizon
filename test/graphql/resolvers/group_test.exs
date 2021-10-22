defmodule Mobilizon.Web.Resolvers.GroupTest do
  use Mobilizon.Web.ConnCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory

  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.GraphQL.AbsintheHelpers

  @non_existent_username "nonexistent"
  @new_group_params %{groupname: "new group"}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "create a group" do
    test "create_group/3 creates a group and check a group with this name does not already exist",
         %{conn: conn, user: user} do
      mutation = """
          mutation {
            createGroup(
              preferred_username: "#{@new_group_params.groupname}"
            ) {
                preferred_username,
                type
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createGroup"]["preferred_username"] ==
               @new_group_params.groupname

      assert json_response(res, 200)["data"]["createGroup"]["type"] == "GROUP"

      mutation = """
          mutation {
            createGroup(
              preferred_username: "#{@new_group_params.groupname}"
            ) {
                preferred_username,
                type
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "A profile or group with that name already exists"
    end
  end

  describe "list groups" do
    @list_groups_query """
    {
        groups {
            elements {
              preferredUsername,
            },
            total
        }
      }
    """

    test "list_groups/3 doesn't returns all groups if not authenticated", %{conn: conn} do
      insert(:group, visibility: :public)
      insert(:group, visibility: :unlisted)
      insert(:group, visibility: :private)

      res = AbsintheHelpers.graphql_query(conn, query: @list_groups_query)

      assert hd(res["errors"])["message"] == "You may not list groups unless moderator."
    end

    test "list_groups/3 doesn't return all groups if not a moderator", %{conn: conn} do
      insert(:group, visibility: :public)
      insert(:group, visibility: :unlisted)
      insert(:group, visibility: :private)
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @list_groups_query)

      assert hd(res["errors"])["message"] == "You may not list groups unless moderator."
    end

    test "list_groups/3 returns all groups if a moderator", %{conn: conn} do
      group_1 = insert(:group, visibility: :public)
      group_2 = insert(:group, visibility: :unlisted)
      group_3 = insert(:group, visibility: :private)
      user = insert(:user, role: :moderator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @list_groups_query)

      assert res["data"]["groups"]["total"] == 3

      assert res["data"]["groups"]["elements"]
             |> Enum.map(& &1["preferredUsername"])
             |> MapSet.new() ==
               [group_1, group_2, group_3] |> Enum.map(& &1.preferred_username) |> MapSet.new()
    end
  end

  describe "find a group" do
    @group_query """
      query Group($preferredUsername: String!) {
        group(preferredUsername: $preferredUsername) {
            preferredUsername,
            members {
              total,
              elements {
                role,
                actor {
                  preferredUsername
                }
              }
            }
        }
      }
    """

    test "find_group/3 returns a group by its username", %{conn: conn, actor: actor, user: user} do
      user2 = insert(:user)
      insert(:actor, user: user2)
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)
      insert(:member, parent: group, role: :member)

      # Unlogged
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{
            preferredUsername: group.preferred_username
          }
        )

      assert res["errors"] == nil

      assert res["data"]["group"]["preferredUsername"] ==
               group.preferred_username

      assert res["data"]["group"]["members"]["total"] == 2
      assert res["data"]["group"]["members"]["elements"] == []

      # Login with non-member
      res =
        conn
        |> auth_conn(user2)
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{
            preferredUsername: group.preferred_username
          }
        )

      assert res["errors"] == nil

      assert res["data"]["group"]["preferredUsername"] ==
               group.preferred_username

      assert res["data"]["group"]["members"]["total"] == 2
      assert res["data"]["group"]["members"]["elements"] == []

      # Login with member
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{
            preferredUsername: group.preferred_username,
            actorId: actor.id
          }
        )

      assert res["errors"] == nil

      assert res["data"]["group"]["members"]["total"] == 2

      admin =
        res["data"]["group"]["members"]["elements"]
        |> Enum.find(&(&1["role"] == "ADMINISTRATOR"))

      assert admin["actor"]["preferredUsername"] ==
               actor.preferred_username

      # Non existent username
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{preferredUsername: @non_existent_username}
        )

      assert res["data"]["group"] == nil

      assert hd(res["errors"])["message"] == "Group not found"
    end

    test "find_group doesn't list group members access if group is private", %{
      conn: conn,
      actor: actor
    } do
      group = insert(:group, visibility: :private)
      insert(:member, parent: group, actor: actor, role: :administrator)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{
            preferredUsername: group.preferred_username
          }
        )

      assert res["errors"] == nil

      assert res["data"]["group"]["preferredUsername"] ==
               group.preferred_username

      assert res["data"]["group"]["members"] == %{"elements" => [], "total" => 1}
    end
  end

  describe "update a group" do
    @update_group_mutation """
      mutation UpdateGroup(
      $id: ID!
      $name: String
      $summary: String
      $avatar: MediaInput
      $banner: MediaInput
      $visibility: GroupVisibility
      $physicalAddress: AddressInput
      ) {
        updateGroup(
          id: $id
          name: $name
          summary: $summary
          banner: $banner
          avatar: $avatar
          visibility: $visibility
          physicalAddress: $physicalAddress
        ) {
          id
          preferredUsername
          name
          summary
          visibility
          avatar {
            url
          }
          banner {
            url
          }
        }
      }
    """
    @new_group_name "new name for group"

    test "update_group/3 updates a group", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_mutation,
          variables: %{
            id: group.id,
            name: @new_group_name,
            visibility: "UNLISTED"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["updateGroup"]["name"] == @new_group_name
      assert res["data"]["updateGroup"]["visibility"] == "UNLISTED"
    end

    test "update_group/3 requires to be logged-in to update a group", %{conn: conn} do
      group = insert(:group)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @update_group_mutation,
          variables: %{id: group.id, name: @new_group_name}
        )

      assert hd(res["errors"])["message"] == "You need to be logged-in to update a group"
    end

    test "update_group/3 requires to be an admin of the group to update a group", %{
      conn: conn,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)
      user = insert(:user)
      actor2 = insert(:actor, user: user)

      # Actor not member
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_mutation,
          variables: %{id: group.id, name: @new_group_name}
        )

      assert hd(res["errors"])["message"] == "Profile is not administrator for the group"

      # Actor member but not admin
      insert(:member, parent: group, actor: actor2, role: :moderator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_mutation,
          variables: %{id: group.id, name: @new_group_name}
        )

      assert hd(res["errors"])["message"] == "Profile is not administrator for the group"
    end
  end

  describe "delete a group" do
    @delete_group_mutation """
    mutation DeleteGroup($groupId: ID!) {
      deleteGroup(
        groupId: $groupId
      ) {
          id
        }
      }
    """

    test "delete_group/3 deletes a group", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_group_mutation,
          variables: %{groupId: group.id}
        )

      assert res["errors"] == nil
      assert res["data"]["deleteGroup"]["id"] == to_string(group.id)

      assert_enqueued(
        worker: Mobilizon.Service.Workers.Background,
        args: %{
          "actor_id" => group.id,
          "author_id" => actor.id,
          "op" => "delete_actor",
          "reserve_username" => true,
          "suspension" => false
        }
      )

      # Can't be used right now, probably because we try to run a transaction in a Oban Job while using Ecto Sandbox

      # assert %{success: 1, snoozed: 0, failure: 0} == Oban.drain_queue(queue: :background)

      # res =
      #   conn
      #   |> auth_conn(user)
      #   |> AbsintheHelpers.graphql_query(
      #     query: @delete_group_mutation,
      #     variables: %{groupId: group.id}
      #   )

      # assert res["data"] == "tt"
      # assert hd(json_response(res, 200)["errors"])["message"] =~ "not found"
    end

    test "delete_group/3 should check user authentication", %{conn: conn, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @delete_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "logged-in"
    end

    test "delete_group/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] ==
               "Current profile is not an administrator of the selected group"
    end

    test "delete_group/3 should check the actor is a member of this group", %{
      conn: conn,
      user: user
    } do
      group = insert(:group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "not a member"
    end

    test "delete_group/3 should check the actor is an administrator of this group", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "not an administrator"
    end
  end

  describe "follow a group" do
    @follow_group_mutation """
    mutation FollowGroup($groupId: ID!, $notify: Boolean) {
      followGroup(groupId: $groupId, notify: $notify) {
        id
      }
    }
    """

    test "when not authenticated", %{conn: conn, user: _user} do
      %Actor{type: :Group} = group = insert(:group)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @follow_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] == "You need to be logged-in to follow a group"
    end

    test "when group doesn't exist", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @follow_group_mutation,
          variables: %{groupId: "89542"}
        )

      assert hd(res["errors"])["message"] == "Group not found"
    end

    test "success", %{conn: conn, user: user} do
      %Actor{type: :Group} = group = insert(:group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @follow_group_mutation,
          variables: %{groupId: group.id}
        )

      assert res["errors"] == nil
    end
  end

  describe "unfollow a group" do
    @unfollow_group_mutation """
    mutation UnfollowGroup($groupId: ID!) {
      unfollowGroup(groupId: $groupId) {
        id
      }
    }
    """

    test "when not authenticated", %{conn: conn, user: _user} do
      %Actor{type: :Group} = group = insert(:group)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @unfollow_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] == "You need to be logged-in to unfollow a group"
    end

    test "when group doesn't exist", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unfollow_group_mutation,
          variables: %{groupId: "89542"}
        )

      assert hd(res["errors"])["message"] == "Group not found"
    end

    test "when the profile is not following the group", %{conn: conn, user: user} do
      %Actor{type: :Group} = group = insert(:group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unfollow_group_mutation,
          variables: %{groupId: group.id}
        )

      assert hd(res["errors"])["message"] =~ "Could not unfollow actor: you are not following"
    end

    test "success", %{conn: conn, user: user, actor: actor} do
      %Actor{type: :Group} = group = insert(:group)

      Mobilizon.Actors.follow(group, actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unfollow_group_mutation,
          variables: %{groupId: group.id}
        )

      assert res["errors"] == nil
      assert Mobilizon.Actors.get_follower_by_followed_and_following(group, actor) == nil
    end
  end

  describe "update a group follow" do
    @update_group_follow_mutation """
    mutation UpdateGroupFollow($followId: ID!, $notify: Boolean) {
      updateGroupFollow(followId: $followId, notify: $notify) {
        id
        notify
      }
    }
    """
    test "when not authenticated", %{conn: conn, user: _user, actor: actor} do
      %Actor{type: :Group} = group = insert(:group)
      follow = insert(:follower, target_actor: group, actor: actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @update_group_follow_mutation,
          variables: %{followId: follow.id}
        )

      assert hd(res["errors"])["message"] == "You need to be logged-in to update a group follow"
    end

    test "when follow doesn't exist", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_follow_mutation,
          variables: %{followId: "d7c83493-e4a0-42a2-a15d-a469e955e80a"}
        )

      assert hd(res["errors"])["message"] == "Follow not found"
    end

    test "when follow does not match the current actor", %{conn: conn, user: user} do
      %Actor{type: :Group} = group = insert(:group)
      follow = insert(:follower, target_actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_follow_mutation,
          variables: %{followId: follow.id}
        )

      assert hd(res["errors"])["message"] == "Follow does not match your account"
    end

    test "success", %{conn: conn, user: user, actor: actor} do
      %Actor{type: :Group} = group = insert(:group)
      follow = insert(:follower, target_actor: group, actor: actor)

      assert %Follower{notify: true} =
               Mobilizon.Actors.get_follower_by_followed_and_following(group, actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_group_follow_mutation,
          variables: %{followId: follow.id, notify: false}
        )

      assert res["errors"] == nil
      assert res["data"]["updateGroupFollow"]["notify"] == false

      assert %Follower{notify: false} =
               Mobilizon.Actors.get_follower_by_followed_and_following(group, actor)
    end
  end
end
