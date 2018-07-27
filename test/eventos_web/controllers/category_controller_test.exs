defmodule EventosWeb.CategoryControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Category

  @create_attrs %{description: "some description", picture: "some picture", title: "some title"}
  @update_attrs %{
    description: "some updated description",
    picture: "some updated picture",
    title: "some updated title"
  }
  @invalid_attrs %{description: nil, picture: nil, title: nil}

  def fixture(:category) do
    {:ok, category} = Events.create_category(@create_attrs)
    category
  end

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all categories", %{conn: conn} do
      conn = get(conn, category_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create category" do
    test "renders category when data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post(conn, category_path(conn, :create), category: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, category_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "description" => "some description",
               "picture" => "some picture",
               "title" => "some title"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post(conn, category_path(conn, :create), category: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update category" do
    setup [:create_category]

    test "renders category when data is valid", %{
      conn: conn,
      category: %Category{id: id} = category,
      user: user
    } do
      conn = auth_conn(conn, user)
      conn = put(conn, category_path(conn, :update, category), category: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, category_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "description" => "some updated description",
               "picture" => "some updated picture",
               "title" => "some updated title"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, category: category, user: user} do
      conn = auth_conn(conn, user)
      conn = put(conn, category_path(conn, :update, category), category: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete category" do
    setup [:create_category]

    test "deletes chosen category", %{conn: conn, category: category, user: user} do
      conn = auth_conn(conn, user)
      conn = delete(conn, category_path(conn, :delete, category))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, category_path(conn, :show, category))
      end)
    end
  end

  defp create_category(_) do
    category = fixture(:category)
    {:ok, category: category}
  end
end
