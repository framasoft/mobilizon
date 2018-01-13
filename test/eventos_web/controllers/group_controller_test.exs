defmodule EventosWeb.GroupControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Groups
  alias Eventos.Groups.Group

  @create_attrs %{description: "some description", suspended: true, title: "some title", uri: "some uri", url: "some url"}
  @update_attrs %{description: "some updated description", suspended: false, title: "some updated title", uri: "some updated uri", url: "some updated url"}
  @invalid_attrs %{description: nil, suspended: nil, title: nil, uri: nil, url: nil}

  def fixture(:group) do
    {:ok, group} = Groups.create_group(@create_attrs)
    group
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all groups", %{conn: conn} do
      conn = get conn, group_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create group" do
    test "renders group when data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, group_path(conn, :create), group: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, group_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some description",
        "suspended" => true,
        "title" => "some title",
        "uri" => "some uri",
        "url" => "some url"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, group_path(conn, :create), group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update group" do
    setup [:create_group]

    test "renders group when data is valid", %{conn: conn, group: %Group{id: id} = group, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, group_path(conn, :update, group), group: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, group_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some updated description",
        "suspended" => false,
        "title" => "some updated title",
        "uri" => "some updated uri",
        "url" => "some updated url"}
    end

    test "renders errors when data is invalid", %{conn: conn, group: group, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, group_path(conn, :update, group), group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete group" do
    setup [:create_group]

    test "deletes chosen group", %{conn: conn, group: group, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, group_path(conn, :delete, group)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, group_path(conn, :show, group)
      end
    end
  end

  defp create_group(_) do
    group = fixture(:group)
    {:ok, group: group}
  end

  defp auth_conn(conn, %Eventos.Accounts.User{} = user) do
    {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end
end
