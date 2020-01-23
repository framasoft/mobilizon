defmodule MobilizonWeb.Resolvers.GroupResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @non_existent_username "nonexistent"
  @new_group_params %{groupname: "new group"}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Group Resolver" do
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

    test "list_groups/3 returns all public or unlisted groups", context do
      group = insert(:group, visibility: :unlisted)
      insert(:group, visibility: :private)

      query = """
      {
        groups {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "groups"))

      assert length(json_response(res, 200)["data"]["groups"]) == 1

      assert hd(json_response(res, 200)["data"]["groups"])["preferredUsername"] ==
               group.preferred_username
    end

    test "find_group/3 returns a group by its username", context do
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
