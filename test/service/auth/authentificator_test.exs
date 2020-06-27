defmodule Mobilizon.Service.Auth.AuthenticatorTest do
  use Mobilizon.DataCase

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import Mobilizon.Factory

  @email "email@domain.tld"
  @password "password"

  describe "test authentification" do
    test "authenticate/1 checks the user's password" do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})
      Users.update_user(user, %{confirmed_at: DateTime.utc_now()})

      assert {:ok, _} = Authenticator.authenticate(@email, @password)

      assert {:error, :bad_password} ==
               Authenticator.authenticate(@email, "completely wrong password")
    end
  end

  describe "fetch_user/1" do
    test "returns user by email" do
      user = insert(:user)
      assert Authenticator.fetch_user(user.email).id == user.id
    end

    test "returns nil" do
      assert Authenticator.fetch_user("email") == {:error, :user_not_found}
    end
  end
end
