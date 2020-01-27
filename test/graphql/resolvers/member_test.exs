defmodule Mobilizon.GraphQL.Resolvers.MemberTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Member Resolver" do
    test "join_group/3 should create a member", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)

      mutation = """
          mutation {
            joinGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
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

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinGroup"]["role"] == "not_approved"
      assert json_response(res, 200)["data"]["joinGroup"]["parent"]["id"] == to_string(group.id)
      assert json_response(res, 200)["data"]["joinGroup"]["actor"]["id"] == to_string(actor.id)

      mutation = """
         mutation {
            joinGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "already a member"
    end

    test "join_group/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user
    } do
      group = insert(:group)

      mutation = """
          mutation {
            joinGroup(
              actor_id: 1042,
              group_id: #{group.id}
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "join_group/3 should check the group is not invite only", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      group = insert(:group, %{openness: :invite_only})

      mutation = """
          mutation {
            joinGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "cannot join this group"
    end

    test "join_group/3 should check the group exists", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      mutation = """
          mutation {
            joinGroup(
              actor_id: #{actor.id},
              group_id: 1042
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "Group id not found"
    end

    test "leave_group/3 should delete a member from a group", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      mutation = """
          mutation {
            leaveGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                actor {
                  id
                },
                parent {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["leaveGroup"]["parent"]["id"] == to_string(group.id)
      assert json_response(res, 200)["data"]["leaveGroup"]["actor"]["id"] == to_string(actor.id)
    end

    test "leave_group/3 should check if the member is the only administrator", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, role: :creator, parent: group})
      insert(:member, %{parent: group})

      mutation = """
          mutation {
            leaveGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                actor {
                  id
                },
                parent {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "only administrator"
    end

    test "leave_group/3 should check the user is logged in", %{conn: conn, actor: actor} do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      mutation = """
          mutation {
            leaveGroup(
              actor_id: #{actor.id},
              group_id: #{group.id}
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "logged-in"
    end

    test "leave_group/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      mutation = """
          mutation {
            leaveGroup(
              actor_id: 1042,
              group_id: #{group.id}
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "leave_group/3 should check the member exists", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      group = insert(:group)
      insert(:member, %{actor: actor, parent: group})

      mutation = """
          mutation {
            leaveGroup(
              actor_id: #{actor.id},
              group_id: 1042
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "Member not found"
    end
  end
end
