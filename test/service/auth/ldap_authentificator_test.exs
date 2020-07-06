defmodule Mobilizon.Service.Auth.LDAPAuthenticatorTest do
  use Mobilizon.Web.ConnCase
  use Mobilizon.Tests.Helpers

  alias Mobilizon.GraphQL.AbsintheHelpers
  alias Mobilizon.Service.Auth.{Authenticator, LDAPAuthenticator}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Auth.Guardian

  import Mobilizon.Factory
  import ExUnit.CaptureLog
  import Mock

  @skip if !Code.ensure_loaded?(:eldap), do: :skip
  @admin_password "admin_password"

  setup_all do
    clear_config([:ldap, :enabled], true)
    clear_config([:ldap, :bind_uid], "admin")
    clear_config([:ldap, :bind_password], @admin_password)
  end

  setup_all do:
              clear_config(
                Authenticator,
                LDAPAuthenticator
              )

  @login_mutation """
  mutation Login($email: String!, $password: String!) {
    login(email: $email, password: $password) {
        accessToken,
        refreshToken,
        user {
          id
        }
      }
    }
  """

  describe "login" do
    @tag @skip
    test "authorizes the existing user using LDAP credentials", %{conn: conn} do
      user_password = "testpassword"
      admin_password = "admin_password"
      user = insert(:user, password_hash: Argon2.hash_pwd_salt(user_password))

      host = [:ldap, :host] |> Mobilizon.Config.get() |> to_charlist
      port = Mobilizon.Config.get([:ldap, :port])

      with_mocks [
        {:eldap, [],
         [
           open: fn [^host], [{:port, ^port}, {:ssl, false} | _] -> {:ok, self()} end,
           simple_bind: fn _connection, _dn, password ->
             case password do
               ^admin_password -> :ok
               ^user_password -> :ok
             end
           end,
           equalityMatch: fn _type, _value -> :ok end,
           wholeSubtree: fn -> :ok end,
           search: fn _connection, _options ->
             {:ok,
              {:eldap_search_result, [{:eldap_entry, '', [{'cn', [to_charlist("MyUser")]}]}], []}}
           end,
           close: fn _connection ->
             send(self(), :close_connection)
             :ok
           end
         ]}
      ] do
        res =
          conn
          |> AbsintheHelpers.graphql_query(
            query: @login_mutation,
            variables: %{email: user.email, password: user_password}
          )

        assert is_nil(res["error"])
        assert token = res["data"]["login"]["accessToken"]

        {:ok, %User{} = user_from_token, _claims} = Guardian.resource_from_token(token)

        assert user_from_token.id == user.id
        assert_received :close_connection
      end
    end

    @tag @skip
    test "creates a new user after successful LDAP authorization", %{conn: conn} do
      user_password = "testpassword"
      admin_password = "admin_password"
      user = build(:user)

      host = [:ldap, :host] |> Mobilizon.Config.get() |> to_charlist
      port = Mobilizon.Config.get([:ldap, :port])

      with_mocks [
        {:eldap, [],
         [
           open: fn [^host], [{:port, ^port}, {:ssl, false} | _] -> {:ok, self()} end,
           simple_bind: fn _connection, _dn, password ->
             case password do
               ^admin_password -> :ok
               ^user_password -> :ok
             end
           end,
           equalityMatch: fn _type, _value -> :ok end,
           wholeSubtree: fn -> :ok end,
           search: fn _connection, _options ->
             {:ok,
              {:eldap_search_result, [{:eldap_entry, '', [{'cn', [to_charlist("MyUser")]}]}], []}}
           end,
           close: fn _connection ->
             send(self(), :close_connection)
             :ok
           end
         ]}
      ] do
        res =
          conn
          |> AbsintheHelpers.graphql_query(
            query: @login_mutation,
            variables: %{email: user.email, password: user_password}
          )

        assert is_nil(res["error"])
        assert token = res["data"]["login"]["accessToken"]

        {:ok, %User{} = user_from_token, _claims} = Guardian.resource_from_token(token)

        assert user_from_token.email == user.email
        assert_received :close_connection
      end
    end

    @tag @skip
    test "falls back to the default authorization when LDAP is unavailable", %{conn: conn} do
      user_password = "testpassword"
      admin_password = "admin_password"
      user = insert(:user, password_hash: Argon2.hash_pwd_salt(user_password))

      host = [:ldap, :host] |> Mobilizon.Config.get() |> to_charlist
      port = Mobilizon.Config.get([:ldap, :port])

      with_mocks [
        {:eldap, [],
         [
           open: fn [^host], [{:port, ^port}, {:ssl, false} | _] -> {:error, 'connect failed'} end,
           simple_bind: fn _connection, _dn, password ->
             case password do
               ^admin_password -> :ok
               ^user_password -> :ok
             end
           end,
           equalityMatch: fn _type, _value -> :ok end,
           wholeSubtree: fn -> :ok end,
           search: fn _connection, _options ->
             {:ok,
              {:eldap_search_result, [{:eldap_entry, '', [{'cn', [to_charlist("MyUser")]}]}], []}}
           end,
           close: fn _connection ->
             send(self(), :close_connection)
             :ok
           end
         ]}
      ] do
        log =
          capture_log(fn ->
            res =
              conn
              |> AbsintheHelpers.graphql_query(
                query: @login_mutation,
                variables: %{email: user.email, password: user_password}
              )

            assert is_nil(res["error"])
            assert token = res["data"]["login"]["accessToken"]

            {:ok, %User{} = user_from_token, _claims} = Guardian.resource_from_token(token)

            assert user_from_token.email == user.email
          end)

        assert log =~ "Could not open LDAP connection: 'connect failed'"
        refute_received :close_connection
      end
    end

    @tag @skip
    test "disallow authorization for wrong LDAP credentials", %{conn: conn} do
      user_password = "testpassword"
      user = insert(:user, password_hash: Argon2.hash_pwd_salt(user_password))

      host = [:ldap, :host] |> Mobilizon.Config.get() |> to_charlist
      port = Mobilizon.Config.get([:ldap, :port])

      with_mocks [
        {:eldap, [],
         [
           open: fn [^host], [{:port, ^port}, {:ssl, false} | _] -> {:ok, self()} end,
           simple_bind: fn _connection, _dn, _password -> {:error, :invalidCredentials} end,
           close: fn _connection ->
             send(self(), :close_connection)
             :ok
           end
         ]}
      ] do
        res =
          conn
          |> AbsintheHelpers.graphql_query(
            query: @login_mutation,
            variables: %{email: user.email, password: user_password}
          )

        refute is_nil(res["errors"])

        assert assert hd(res["errors"])["message"] ==
                        "Impossible to authenticate, either your email or password are invalid."

        assert_received :close_connection
      end
    end
  end

  describe "can change" do
    test "password" do
      assert LDAPAuthenticator.can_change_password?(%User{provider: "ldap"}) == false
      assert LDAPAuthenticator.can_change_password?(%User{provider: nil}) == true
    end

    test "email" do
      assert LDAPAuthenticator.can_change_password?(%User{provider: "ldap"}) == false
      assert LDAPAuthenticator.can_change_password?(%User{provider: nil}) == true
    end
  end
end
