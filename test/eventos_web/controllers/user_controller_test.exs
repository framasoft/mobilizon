defmodule MobilizonWeb.UserControllerTest do
  use MobilizonWeb.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors
  alias Mobilizon.Actors.User
  use Bamboo.Test

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
    {:ok, conn: conn, user: user, actor: actor}
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
      conn = post(conn, user_path(conn, :register), @create_attrs)
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(@create_attrs.email)
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, user_path(conn, :register), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders user with avatar when email is valid", %{conn: conn} do
      attrs = %{
        email: "contact@framasoft.org",
        password: "some password_hash",
        username: "framasoft"
      }

      conn = post(conn, user_path(conn, :register), attrs)
      assert %{"email" => "contact@framasoft.org"} = json_response(conn, 201)
    end
  end

  describe "validating user" do
    test "validate user when token is valid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @create_attrs)
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(@create_attrs.email)
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))

      conn = get(conn, user_path(conn, :validate, user.confirmation_token))
      assert %{"user" => _, "token" => _} = json_response(conn, 200)
    end

    test "validate user when token is invalid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @create_attrs)
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(@create_attrs.email)
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))

      conn = get(conn, user_path(conn, :validate, "toto"))
      assert %{"error" => _} = json_response(conn, 404)
    end
  end

  describe "revalidating user" do
    test "ask to resend token to user when too soon", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @create_attrs)
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(@create_attrs.email)
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))

      conn = post(conn, user_path(conn, :resend_confirmation), %{"email" => @create_attrs.email})
      assert %{"error" => _} = json_response(conn, 404)
    end

    test "ask to resend token to user when the time is right", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), @create_attrs)

      assert %{"email" => "foo@bar.tld"} = json_response(conn, 201)
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(@create_attrs.email)
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))

      # Hammer time !
      {:ok, %User{} = user} =
        Mobilizon.Actors.update_user(user, %{
          confirmation_sent_at: Timex.shift(user.confirmation_sent_at, hours: -3)
        })

      conn = post(conn, user_path(conn, :resend_confirmation), %{"email" => @create_attrs.email})
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))
      assert %{"email" => "foo@bar.tld"} = json_response(conn, 200)
    end
  end

  describe "resetting user's password" do
    test "ask for reset", %{conn: conn, user: user} do
      user_email = user.email

      # Send reset email
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => user_email})
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(user.email)
      assert_delivered_email(Mobilizon.Email.User.reset_password_email(user))
      assert %{"email" => user_email} = json_response(conn, 200)

      # Call reset route
      conn =
        post(conn, user_path(conn, :reset_password), %{
          "password" => "new password",
          "token" => user.reset_password_token
        })

      user_id = user.id
      assert %{"user" => %{"id" => user_id}} = json_response(conn, 200)
    end

    test "ask twice for reset too soon", %{conn: conn, user: user} do
      user_email = user.email

      # Send reset email
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => user.email})
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(user.email)
      assert_delivered_email(Mobilizon.Email.User.reset_password_email(user))
      assert %{"email" => user_email} = json_response(conn, 200)

      # Send reset email again
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => user.email})

      assert %{"errors" => "You requested a new reset password too early"} =
               json_response(conn, 404)
    end

    test "ask twice for reset after a while", %{conn: conn, user: user} do
      user_email = user.email

      # Send reset email
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => user.email})
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(user.email)
      assert_delivered_email(Mobilizon.Email.User.reset_password_email(user))
      assert %{"email" => user_email} = json_response(conn, 200)

      # Hammer time !
      {:ok, %User{} = user} =
        Mobilizon.Actors.update_user(user, %{
          reset_password_sent_at: Timex.shift(user.reset_password_sent_at, hours: -3)
        })

      # Send reset email again
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => user.email})
      assert {:ok, %User{} = user} = Mobilizon.Actors.get_user_by_email(user.email)
      assert_delivered_email(Mobilizon.Email.User.reset_password_email(user))
      assert %{"email" => user_email} = json_response(conn, 200)
    end

    test "ask for reset with wrong address", %{conn: conn} do
      conn = post(conn, user_path(conn, :send_reset_password), %{"email" => "yolo@coucou"})
      assert %{"errors" => "Unable to find an user with this email"} = json_response(conn, 404)
    end

    test "calling reset route with wrong token", %{conn: conn} do
      conn =
        post(conn, user_path(conn, :reset_password), %{
          "password" => "new password",
          "token" => "just wrong"
        })

      assert %{"errors" => %{"token" => ["Wrong token for password reset"]}} =
               json_response(conn, 404)
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
