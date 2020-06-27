defmodule Mobilizon.Service.Auth.MobilizonAuthenticatorTest do
  use Mobilizon.DataCase

  alias Mobilizon.Service.Auth.MobilizonAuthenticator
  alias Mobilizon.Users.User
  import Mobilizon.Factory

  setup do
    password = "testpassword"
    email = "someone@somewhere.tld"
    user = insert(:user, email: email, password_hash: Argon2.hash_pwd_salt(password))
    {:ok, [user: user, email: email, password: password]}
  end

  test "login", %{email: email, password: password, user: user} do
    assert {:ok, %User{} = returned_user} = MobilizonAuthenticator.login(email, password)
    assert returned_user.id == user.id
  end

  test "login with invalid password", %{email: email} do
    assert {:error, :bad_password} == MobilizonAuthenticator.login(email, "invalid")
    assert {:error, :bad_password} == MobilizonAuthenticator.login(email, nil)
  end

  test "login with no credentials" do
    assert {:error, :user_not_found} == MobilizonAuthenticator.login("some@email.com", nil)
    assert {:error, :user_not_found} == MobilizonAuthenticator.login(nil, nil)
  end
end
