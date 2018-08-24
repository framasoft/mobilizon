defmodule EventosWeb.ActorControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Actors

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: conn, user: user, actor: actor}
  end

  @create_attrs %{
    preferred_username: "otheridentity",
    summary: "This is my other identity"
  }

  describe "index" do
    test "lists all actors", %{conn: conn, user: user, actor: actor} do
      conn = get(conn, actor_path(conn, :index))
      assert hd(json_response(conn, 200)["data"])["username"] == actor.preferred_username
    end
  end

  describe "create actor" do
    test "from an existing user", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post(conn, actor_path(conn, :create), actor: @create_attrs)
      assert json_response(conn, 201)["data"]["username"] == @create_attrs.preferred_username
    end
  end

  describe "show actor" do
    test "show existing actor", %{conn: conn, actor: actor} do
      actor_id = actor.id
      conn = get(conn, actor_path(conn, :show, actor.preferred_username))
      assert %{"data" => %{"id" => actor_id}} = json_response(conn, 200)
    end

    test "show non-existing actor", %{conn: conn, actor: actor} do
      actor_id = actor.id
      conn = get(conn, actor_path(conn, :show, "nonexisting"))
      assert "" == response(conn, 404)
    end
  end

  describe "search for actors" do
    test "search for existing actors", %{conn: conn, actor: actor} do
      actor_username = actor.preferred_username
      conn = get(conn, actor_path(conn, :search, actor_username))
      assert %{"data" => [%{"username" => actor_username}]} = json_response(conn, 200)
    end

    test "search for existing actors with similar username", %{conn: conn, actor: actor} do
      actor_username = actor.preferred_username
      conn = get(conn, actor_path(conn, :search, "thom"))
      assert %{"data" => [%{"username" => actor_username}]} = json_response(conn, 200)
    end

    test "search for nothing", %{conn: conn, actor: actor} do
      actor_username = actor.preferred_username
      conn = get(conn, actor_path(conn, :search, "nothing"))
      assert %{"data" => []} = json_response(conn, 200)
    end
  end

  describe "update actor" do
    test "update actor with valid attrs", %{conn: conn, user: user, actor: actor} do
      conn = auth_conn(conn, user)

      conn =
        patch(conn, actor_path(conn, :update, actor.preferred_username), %{
          "actor" => %{"name" => "glouglou"}
        })

      assert %{"data" => %{"display_name" => "glouglou"}} = json_response(conn, 200)
    end

    test "update actor with invalid attrs", %{conn: conn, user: user, actor: actor} do
      conn = auth_conn(conn, user)

      conn =
        patch(conn, actor_path(conn, :update, actor.preferred_username), %{
          "actor" => %{"preferred_username" => nil}
        })

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  ###
  # Not possible atm
  ###
  #  describe "delete actor" do
  #    setup [:create_actor]
  #
  #    test "deletes own actor", %{conn: conn, user: user} do
  #      conn = auth_conn(conn, user)
  #      conn = delete conn, actor_path(conn, :delete, user.actor)
  #      assert response(conn, 204)
  #      assert_error_sent 404, fn ->
  #        get conn, actor_path(conn, :show, user.actor)
  #      end
  #    end
  #
  #    test "deletes other actor", %{conn: conn, actor: actor, user: user} do
  #      conn = auth_conn(conn, user)
  #      conn = delete conn, actor_path(conn, :delete, actor)
  #      assert response(conn, 401)
  #      conn = get conn, actor_path(conn, :show, actor)
  #      assert response(conn, 200)
  #    end
  #  end

  @create_group_attrs %{
    preferred_username: "mygroup",
    summary: "This is my awesome group",
    name: "My Group"
  }

  describe "index groups" do
    test "lists all actor groups", %{conn: conn} do
      conn = get(conn, group_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "after creating a group", %{conn: conn, user: user, actor: actor} do
      # create group
      conn = auth_conn(conn, user)
      create_group_attrs = Map.put(@create_group_attrs, :actor_admin, actor.preferred_username)
      conn = post(conn, group_path(conn, :create), group: create_group_attrs)

      group_res = json_response(conn, 201)
      assert group_res["username"] == @create_group_attrs.preferred_username

      conn = get(conn, group_path(conn, :index))
      assert json_response(conn, 200)["data"] == [group_res]
    end
  end

  describe "create group" do
    test "with valid attributes", %{conn: conn, user: user, actor: actor} do
      conn = auth_conn(conn, user)
      create_group_attrs = Map.put(@create_group_attrs, :actor_admin, actor.preferred_username)
      conn = post(conn, group_path(conn, :create), group: create_group_attrs)

      assert json_response(conn, 201)["username"] == @create_group_attrs.preferred_username
    end
  end

  describe "join group" do
    setup %{conn: conn} do
      user = insert(:user)
      actor = insert(:actor, user: user)
      group = insert(:group, preferred_username: "mygroup")
      {:ok, conn: conn, user: user, actor: actor, group: group}
    end

    test "from valid account", %{conn: conn, user: user, actor: actor, group: group} do
      conn = auth_conn(conn, user)

      conn =
        post(conn, group_path(conn, :join, group.preferred_username), %{
          "actor_name" => actor.preferred_username
        })

      resp = json_response(conn, 201)

      assert resp = %{
               "actor" => %{"username" => actor.preferred_username},
               "group" => %{"username" => group.preferred_username},
               "role" => 0
             }
    end

    test "join non existent group", %{conn: conn, user: user, actor: actor} do
      conn = auth_conn(conn, user)

      conn =
        post(conn, group_path(conn, :join, "mygroup@nonexistent.tld"), %{
          "actor_name" => actor.preferred_username
        })

      resp = json_response(conn, 404)

      assert resp = %{msg: "Resource not found", details: "group or actor doesn't exist"}
    end
  end
end
