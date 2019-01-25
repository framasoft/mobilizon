defmodule MobilizonWeb.Resolvers.GroupResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{User, Actor}
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory
  require Logger

  @non_existent_username "nonexistent"
  @new_group_params %{groupname: "new group"}

  setup %{conn: conn} do
    {:ok, %User{default_actor: %Actor{} = actor} = user} =
      Actors.register(%{email: "test2@test.tld", password: "testest", username: "test"})

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Group Resolver" do
    test "create_group/3 creates a group", %{conn: conn, user: user, actor: actor} do
      mutation = """
          mutation {
            createGroup(
              preferred_username: "#{@new_group_params.groupname}",
              admin_actor_username: "#{actor.preferred_username}"
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
              admin_actor_username: "#{actor.preferred_username}",
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

      assert hd(json_response(res, 200)["errors"])["message"] == "existing_group_name"
    end

    test "list_groups/3 returns all groups", context do
      group = insert(:group)

      query = """
      {
        groups {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert hd(json_response(res, 200)["data"]["groups"])["preferredUsername"] ==
               group.preferred_username
    end

    test "find_group/3 returns a group by it's username", context do
      group = insert(:group)

      query = """
      {
        group(preferredUsername: "#{group.preferred_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "group"))

      assert json_response(res, 200)["data"]["group"]["preferredUsername"] ==
               group.preferred_username

      query = """
      {
        group(preferredUsername: "#{@non_existent_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "group"))

      assert json_response(res, 200)["data"]["group"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Group with name #{@non_existent_username} not found"
    end

    test "delete_group/3 deletes a group", %{conn: conn, user: user, actor: actor} do
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: 2)

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
      assert json_response(res, 200)["data"]["deleteGroup"]["id"] == group.id

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not found"
    end
  end
end
