defmodule EventosWeb.UserControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Actors
  alias Eventos.Actors.User

  @create_attrs %{email: "foo@bar.tld", password: "some password_hash", username: "some username"}
  # @update_attrs %{email: "foo@fighters.tld", password: "some updated password_hash", username: "some updated username"}
  @invalid_attrs %{email: "not an email", password: nil, username: nil}

  def fixture(:user) do
    {:ok, user} = Actors.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all users", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = get(conn, user_path(conn, :index))
      assert hd(json_response(conn, 200)["data"])["id"] == user.id
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @create_attrs)
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders user with avatar when email is valid", %{conn: conn} do
      attrs = %{
        email: "contact@framasoft.org",
        password: "some password_hash",
        username: "framasoft"
      }

      conn = post(conn, user_path(conn, :create), attrs)
      assert %{"email" => "contact@framasoft.org"} = json_response(conn, 201)
    end
  end

  #  describe "update user" do
  #    setup [:create_user]
  #
  #    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
  #      conn = auth_conn(conn, user)
  #      conn = put conn, user_path(conn, :update, user), user: @update_attrs
  #      assert %{"id" => ^id} = json_response(conn, 200)["data"]
  #
  #      conn = get conn, user_path(conn, :show, id)
  #      assert json_response(conn, 200)["data"] == %{
  #        "id" => id,
  #        "email" => "some updated email",
  #        "password_hash" => "some updated password_hash",
  #        "role" => 43}
  #    end
  #
  #    test "renders errors when data is invalid", %{conn: conn, user: user} do
  #      conn = auth_conn(conn, user)
  #      conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
  #      assert json_response(conn, 422)["errors"] != %{}
  #    end
  #  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = delete(conn, user_path(conn, :delete, user))
      assert response(conn, 204)
    end
  end

  defp create_user(_) do
    user = insert(:user)
    {:ok, user: user}
  end
end
