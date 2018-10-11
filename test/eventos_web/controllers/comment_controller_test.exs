defmodule MobilizonWeb.CommentControllerTest do
  use MobilizonWeb.ConnCase

  alias Mobilizon.Events
  alias Mobilizon.Events.Comment

  import Mobilizon.Factory

  @create_attrs %{text: "some text"}
  @update_attrs %{text: "some updated text"}
  @invalid_attrs %{text: nil, url: nil}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user, actor: actor}
  end

  describe "create comment" do
    test "renders comment when data is valid", %{conn: conn, user: user, actor: actor} do
      conn = auth_conn(conn, user)
      attrs = Map.merge(@create_attrs, %{actor_id: actor.id})
      conn = post(conn, comment_path(conn, :create), comment: attrs)
      assert %{"uuid" => uuid, "id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, comment_path(conn, :show, uuid))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "text" => "some text",
               "uuid" => uuid,
               "url" => "#{MobilizonWeb.Endpoint.url()}/comments/#{uuid}"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post(conn, comment_path(conn, :create), comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update comment" do
    setup [:create_comment]

    test "renders comment when data is valid", %{
      conn: conn,
      comment: %Comment{id: id, uuid: uuid} = comment,
      user: user,
      actor: actor
    } do
      conn = auth_conn(conn, user)
      attrs = Map.merge(@update_attrs, %{actor_id: actor.id})
      conn = put(conn, comment_path(conn, :update, uuid), comment: attrs)
      assert %{"uuid" => uuid, "id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, comment_path(conn, :show, uuid))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "text" => "some updated text",
               "uuid" => uuid,
               "url" => "#{MobilizonWeb.Endpoint.url()}/comments/#{uuid}"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, comment: comment, user: user} do
      conn = auth_conn(conn, user)
      conn = put(conn, comment_path(conn, :update, comment.uuid), comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete comment" do
    setup [:create_comment]

    test "deletes chosen comment", %{
      conn: conn,
      comment: %Comment{uuid: uuid} = comment,
      user: user
    } do
      conn = auth_conn(conn, user)
      conn = delete(conn, comment_path(conn, :delete, uuid))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, comment_path(conn, :show, uuid))
      end)
    end
  end

  defp create_comment(_) do
    comment = insert(:comment)
    {:ok, comment: comment}
  end
end
