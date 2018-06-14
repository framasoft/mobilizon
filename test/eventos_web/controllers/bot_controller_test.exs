defmodule EventosWeb.BotControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Actors
  alias Eventos.Actors.Bot

  @create_attrs %{source: "some source", type: "some type", name: "some name"}
  @update_attrs %{source: "some updated source", type: "some updated type", name: "some updated name"}
  @invalid_attrs %{source: nil, type: nil, name: nil}

  setup %{conn: conn} do
    actor = insert(:actor)
    user = insert(:user, actor: actor)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  describe "index" do
    test "lists all bots", %{conn: conn} do
      conn = get conn, bot_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create bot" do
    test "renders bot when data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, bot_path(conn, :create), bot: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, bot_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "source" => "some source",
        "type" => "some type"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, bot_path(conn, :create), bot: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update bot" do
    setup [:create_bot]

    test "renders bot when data is valid", %{conn: conn, bot: %Bot{id: id} = bot, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, bot_path(conn, :update, bot), bot: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, bot_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "source" => "some updated source",
        "type" => "some updated type"}
    end

    test "renders errors when data is invalid", %{conn: conn, bot: bot, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, bot_path(conn, :update, bot), bot: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete bot" do
    setup [:create_bot]

    test "deletes chosen bot", %{conn: conn, bot: bot, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, bot_path(conn, :delete, bot)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, bot_path(conn, :show, bot)
      end
    end
  end

  defp create_bot(_) do
    bot = insert(:bot)
    {:ok, bot: bot}
  end
end
