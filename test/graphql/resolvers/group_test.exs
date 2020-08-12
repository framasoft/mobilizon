defmodule Mobilizon.Web.Resolvers.GroupTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  @non_existent_username "nonexistent"
  @new_group_params %{groupname: "new group"}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "create a group" do
    test "create_group/3 should check the user owns the identity", %{conn: conn, user: user} do
      another_actor = insert(:actor)

      mutation = """
          mutation {
            createGroup(
              preferred_username: "#{@new_group_params.groupname}",
              creator_actor_id: #{another_actor.id}
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
               "Creator actor id is not owned by the current user"
    end

    test "create_group/3 creates a group and check a group with this name does not already exist",
         %{conn: conn, user: user, actor: actor} do
      mutation = """
          mutation {
            createGroup(
              preferred_username: "#{@new_group_params.groupname}",
              creator_actor_id: #{actor.id}
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
              preferred_username: "#{@new_group_params.groupname}",
              creator_actor_id: #{actor.id},
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
               "A group with this name already exists"
    end
  end

  describe "list groups" do
    test "list_groups/3 returns all public groups", %{conn: conn} do
      group = insert(:group, visibility: :public)
      insert(:group, visibility: :unlisted)
      insert(:group, visibility: :private)

      query = """
      {
        groups {
            elements {
              preferredUsername,
            },
            total
        }
      }
      """

      res = AbsintheHelpers.graphql_query(conn, query: query)

      assert res["data"]["groups"]["total"] == 1

      assert hd(res["data"]["groups"]["elements"])["preferredUsername"] ==
               group.preferred_username
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
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)
      insert(:member, parent: group, role: :member)

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
      assert hd(res["data"]["group"]["members"]["elements"])["role"] == "ADMINISTRATOR"

      assert hd(res["data"]["group"]["members"]["elements"])["actor"]["preferredUsername"] ==
               actor.preferred_username

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_query,
          variables: %{preferredUsername: @non_existent_username}
        )

      assert res["data"]["group"] == nil

      assert hd(res["errors"])["message"] ==
               "Group with name #{@non_existent_username} not found"
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

  describe "delete a group" do
    test "delete_group/3 deletes a group", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :administrator)

      mutation = """
          mutation {
            deleteGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["deleteGroup"]["id"] == to_string(group.id)

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not found"
    end

    test "delete_group/3 should check user authentication", %{conn: conn, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      mutation = """
          mutation {
            deleteGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "logged-in"
    end

    test "delete_group/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      mutation = """
          mutation {
            deleteGroup(
              actor_id: 159,
              group_id: #{group.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "delete_group/3 should check the actor is a member of this group", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)

      mutation = """
          mutation {
            deleteGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not a member"
    end

    test "delete_group/3 should check the actor is an administrator of this group", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      mutation = """
          mutation {
            deleteGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not an administrator"
    end
  end
end
