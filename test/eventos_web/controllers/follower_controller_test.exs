defmodule EventosWeb.FollowerControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Actors
  alias Eventos.Actors.Follower
  import Eventos.Factory

  @create_attrs %{approved: true, score: 42}
  @update_attrs %{approved: false, score: 43}
  @invalid_attrs %{approved: nil, score: nil}

  setup %{conn: conn} do
    actor = insert(:actor)
    target_actor = insert(:actor)

    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     actor: actor,
     target_actor: target_actor}
  end

  describe "create follower" do
    test "renders follower when data is valid", %{
      conn: conn,
      actor: actor,
      target_actor: target_actor
    } do
      create_attrs =
        @create_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:target_actor_id, target_actor.id)

      conn = post(conn, follower_path(conn, :create), follower: create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, follower_path(conn, :show, id))
      assert json_response(conn, 200)["data"] == %{"id" => id, "approved" => true, "score" => 42}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, follower_path(conn, :create), follower: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update follower" do
    setup [:create_follower]

    test "renders follower when data is valid", %{
      conn: conn,
      follower: %Follower{id: id} = follower
    } do
      conn = put(conn, follower_path(conn, :update, follower), follower: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, follower_path(conn, :show, id))
      assert json_response(conn, 200)["data"] == %{"id" => id, "approved" => false, "score" => 43}
    end

    test "renders errors when data is invalid", %{conn: conn, follower: follower} do
      conn = put(conn, follower_path(conn, :update, follower), follower: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete follower" do
    setup [:create_follower]

    test "deletes chosen follower", %{conn: conn, follower: follower} do
      conn = delete(conn, follower_path(conn, :delete, follower))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, follower_path(conn, :show, follower))
      end)
    end
  end

  defp create_follower(%{actor: actor, target_actor: target_actor}) do
    follower = insert(:follower, actor: actor, target_actor: target_actor)
    [follower: follower]
  end
end
