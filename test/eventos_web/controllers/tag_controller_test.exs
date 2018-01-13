defmodule EventosWeb.TagControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Tag

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  def fixture(:tag) do
    {:ok, tag} = Events.create_tag(@create_attrs)
    tag
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all tags", %{conn: conn} do
      conn = get conn, tag_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create tag" do
    test "renders tag when data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, tag_path(conn, :create), tag: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, tag_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "title" => "some title"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, tag_path(conn, :create), tag: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update tag" do
    setup [:create_tag]

    test "renders tag when data is valid", %{conn: conn, tag: %Tag{id: id} = tag, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, tag_path(conn, :update, tag), tag: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, tag_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "title" => "some updated title"}
    end

    test "renders errors when data is invalid", %{conn: conn, tag: tag, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, tag_path(conn, :update, tag), tag: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete tag" do
    setup [:create_tag]

    test "deletes chosen tag", %{conn: conn, tag: tag, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, tag_path(conn, :delete, tag)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, tag_path(conn, :show, tag)
      end
    end
  end

  defp create_tag(_) do
    tag = fixture(:tag)
    {:ok, tag: tag}
  end

  defp auth_conn(conn, %Eventos.Accounts.User{} = user) do
    {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end
end
