defmodule EventosWeb.ActorControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Actors

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: conn, user: user, actor: actor}
  end

  describe "index" do
    test "lists all actors", %{conn: conn, user: user, actor: actor} do
      conn = get conn, actor_path(conn, :index)
      assert hd(json_response(conn, 200)["data"])["username"] == actor.preferred_username
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
end
