defmodule EventosWeb.ActorControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Actors

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: conn, user: user, actor: actor}
  end

  key = :public_key.generate_key({:rsa, 2048, 65_537})
  entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
  pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()

  @create_attrs %{preferred_username: "otheridentity", summary: "This is my other identity", domain: nil, keys: pem, user: nil}

  describe "index" do
    test "lists all actors", %{conn: conn, user: user, actor: actor} do
      conn = get conn, actor_path(conn, :index)
      assert hd(json_response(conn, 200)["data"])["username"] == actor.preferred_username
    end
  end

  describe "create actor" do
    test "from an existing user", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, actor_path(conn, :create), actor: @create_attrs
      assert json_response(conn, 201)["data"]["username"] == @create_attrs.preferred_username
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
