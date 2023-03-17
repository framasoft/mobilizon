defmodule Mobilizon.GraphQL.Resolvers.ApplicationTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory
  require Logger

  alias Mobilizon.Applications.{Application, ApplicationDeviceActivation}
  alias Mobilizon.GraphQL.AbsintheHelpers

  @identities_query """
  query LoggedUser {
    loggedUser {
      actors {
        id
      }
    }
  }
  """

  describe "Authorize an application" do
    @authorize_mutation """
    mutation AuthorizeApplication(
      $applicationClientId: String!
      $redirectURI: String!
      $state: String
      $scope: String!
    ) {
      authorizeApplication(
        clientId: $applicationClientId
        redirectURI: $redirectURI
        state: $state
        scope: $scope
      ) {
        code
        state
        clientId
        scope
      }
    }
    """
    test "while being not logged-in", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @authorize_mutation,
          variables: [
            applicationClientId: "an invalid client_id",
            redirectURI: "doesn't matter",
            state: "hello",
            scope: "read"
          ]
        )

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with incorrect client_id", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @authorize_mutation,
          variables: [
            applicationClientId: "an invalid client_id",
            redirectURI: "doesn't matter",
            state: "hello",
            scope: "read"
          ]
        )

      assert "No application with this client_id was found" = hd(res["errors"])["message"]
    end

    test "with incorrect redirect_uri", %{conn: conn} do
      user = insert(:user)
      app = insert(:auth_application)

      client_id = app.client_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @authorize_mutation,
          variables: [
            applicationClientId: client_id,
            redirectURI: "something not in app's redirect URIs",
            state: "hello",
            scope: "read"
          ]
        )

      assert "The given redirect_uri is not in the list of allowed redirect URIs" =
               hd(res["errors"])["message"]
    end

    test "with correct params", %{conn: conn} do
      user = insert(:user)
      app = insert(:auth_application)

      client_id = app.client_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @authorize_mutation,
          variables: [
            applicationClientId: client_id,
            redirectURI: hd(app.redirect_uris),
            state: "hello",
            scope: "read"
          ]
        )

      assert %{
               "scope" => "read",
               "state" => "hello",
               "clientId" => ^client_id,
               "code" => _code
             } = res["data"]["authorizeApplication"]
    end
  end

  describe "Revoke an application token" do
    @revoke_mutation """
    mutation RevokeApplicationToken($appTokenId: String!) {
      revokeApplicationToken(appTokenId: $appTokenId) {
        id
      }
    }
    """

    test "while not authenticated", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @revoke_mutation,
          variables: [
            appTokenId: "not an actual token ID"
          ]
        )

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with an invalid token", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @revoke_mutation,
          variables: [
            appTokenId: "5846"
          ]
        )

      assert "Application token not found" == hd(res["errors"])["message"]
    end

    test "with valid token", %{conn: conn} do
      user = insert(:user)

      app_token = insert(:auth_application_token, user: user)
      app_token_id = to_string(app_token.id)

      authed_conn = auth_conn(conn, app_token)

      res = AbsintheHelpers.graphql_query(authed_conn, query: @identities_query)
      assert res["errors"] == nil
      assert res["data"]["loggedUser"]["actors"]

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @revoke_mutation,
          variables: [
            appTokenId: app_token_id
          ]
        )

      assert app_token_id == res["data"]["revokeApplicationToken"]["id"]

      # Asserting the token can't be used anymore
      res = AbsintheHelpers.graphql_query(authed_conn, query: @identities_query)
      assert "You need to be logged in" == hd(res["errors"])["message"]
    end
  end

  describe "Get an application" do
    @application_query """
    query AuthApplication($clientId: String!) {
      authApplication(clientId: $clientId) {
        id
        clientId
        name
        website
      }
    }
    """

    test "while not authenticated", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @application_query,
          variables: [
            clientId: "not an actual client ID"
          ]
        )

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with incorrect client_id", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @application_query,
          variables: [
            clientId: "nonsense"
          ]
        )

      assert "Application not found" = hd(res["errors"])["message"]
    end

    test "with valid client_id", %{conn: conn} do
      user = insert(:user)

      %Application{id: app_id, client_id: app_client_id, name: app_name, website: app_website} =
        insert(:auth_application)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @application_query,
          variables: [
            clientId: app_client_id
          ]
        )

      assert is_nil(res["errors"])

      app_id = to_string(app_id)

      assert %{
               "id" => ^app_id,
               "clientId" => ^app_client_id,
               "name" => ^app_name,
               "website" => ^app_website
             } = res["data"]["authApplication"]
    end
  end

  describe "Get user applications" do
    @user_apps_query """
    query AuthAuthorizedApplications {
      loggedUser {
        id
        authAuthorizedApplications {
          id
          application {
            name
            website
          }
          lastUsedAt
          insertedAt
        }
      }
    }
    """

    test "without being logged in", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @user_apps_query)

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with an app token", %{conn: conn} do
      user = insert(:user)
      app_token = insert(:auth_application_token, user: user)

      insert(:auth_application_token, user: user, status: :success, authorization_code: nil)

      insert(:auth_application_token, user: user, status: :success, authorization_code: nil)

      res =
        conn
        |> auth_conn(app_token)
        |> AbsintheHelpers.graphql_query(query: @user_apps_query)

      assert is_nil(res["data"]["loggedUser"]["authAuthorizedApplications"])
      refute is_nil(res["data"]["loggedUser"]["id"])
      assert hd(res["errors"])["message"] =~ "Not authorized to access field"
      assert hd(res["errors"])["path"] == ["loggedUser", "authAuthorizedApplications"]
    end

    test "with authorized applications", %{conn: conn} do
      user = insert(:user)

      app_token_1 =
        insert(:auth_application_token, user: user, status: :success, authorization_code: nil)

      app_token_2 =
        insert(:auth_application_token, user: user, status: :success, authorization_code: nil)

      # Someone else's app token
      app_token_3 = insert(:auth_application_token, status: :success, authorization_code: nil)
      # An app token not activated
      app_token_4 = insert(:auth_application_token, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_apps_query)

      assert is_nil(res["errors"])
      assert 2 = length(res["data"]["loggedUser"]["authAuthorizedApplications"])

      found_app_token_ids =
        res["data"]["loggedUser"]["authAuthorizedApplications"]
        |> Enum.map(&String.to_integer(&1["id"]))
        |> MapSet.new()

      assert MapSet.subset?(MapSet.new([app_token_1.id, app_token_2.id]), found_app_token_ids)
      refute MapSet.member?(found_app_token_ids, app_token_3.id)
      refute MapSet.member?(found_app_token_ids, app_token_4.id)
    end
  end

  describe "Device activation" do
    @device_activation_mutation """
    mutation DeviceActivation($userCode: String!) {
      deviceActivation(userCode: $userCode) {
        id
        application {
          id
          clientId
          name
          website
        }
        scope
      }
    }
    """

    test "without being logged-in", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @device_activation_mutation,
          variables: [userCode: "hi"]
        )

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with a bad code", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_activation_mutation,
          variables: [userCode: "hi"]
        )

      assert "The given user code is invalid" = hd(res["errors"])["message"]
    end

    test "with an expired code", %{conn: conn} do
      user = insert(:user)

      auth_application_device_activation =
        insert(:auth_application_device_activation, user: user, expires_in: -100)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_activation_mutation,
          variables: [userCode: auth_application_device_activation.user_code]
        )

      assert "The given user code has expired" = hd(res["errors"])["message"]
    end

    test "with a valid code", %{conn: conn} do
      user = insert(:user)
      auth_application_device_activation = insert(:auth_application_device_activation, user: nil)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_activation_mutation,
          variables: [userCode: auth_application_device_activation.user_code]
        )

      assert is_nil(res["errors"])

      assert res["data"]["deviceActivation"]["application"]["id"] ==
               to_string(auth_application_device_activation.application.id)
    end
  end

  describe "Device authorization" do
    @device_authorization_mutation """
    mutation AuthorizeDeviceApplication(
      $applicationClientId: String!
      $userCode: String!
    ) {
      authorizeDeviceApplication(
        clientId: $applicationClientId
        userCode: $userCode
      ) {
        clientId
        scope
      }
    }
    """

    test "without being logged in", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @device_authorization_mutation,
          variables: [applicationClientId: "something", userCode: "wrong"]
        )

      assert "You need to be logged in" = hd(res["errors"])["message"]
    end

    test "with a bad code", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_authorization_mutation,
          variables: [applicationClientId: "something", userCode: "wrong"]
        )

      assert "The given user code is invalid" = hd(res["errors"])["message"]
    end

    test "with some code that isn't approved", %{conn: conn} do
      user = insert(:user)

      auth_application_device_activation =
        insert(:auth_application_device_activation, user: user, status: :pending)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_authorization_mutation,
          variables: [
            applicationClientId: auth_application_device_activation.application.client_id,
            userCode: auth_application_device_activation.user_code
          ]
        )

      assert "The device user code was not provided before approving the application" =
               hd(res["errors"])["message"]
    end

    test "with some expired code", %{conn: conn} do
      user = insert(:user)

      auth_application_device_activation =
        insert(:auth_application_device_activation,
          user: user,
          status: :confirmed,
          expires_in: -100
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_authorization_mutation,
          variables: [
            applicationClientId: auth_application_device_activation.application.client_id,
            userCode: auth_application_device_activation.user_code
          ]
        )

      assert "The given user code has expired" = hd(res["errors"])["message"]
    end

    test "with a valid code", %{conn: conn} do
      user = insert(:user)

      %ApplicationDeviceActivation{
        application: %Application{client_id: client_id},
        user_code: user_code
      } = insert(:auth_application_device_activation, user: user, status: :confirmed)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @device_authorization_mutation,
          variables: [
            applicationClientId: client_id,
            userCode: user_code
          ]
        )

      assert is_nil(res["errors"])

      assert %{
               "clientId" => ^client_id,
               "scope" => _scope
             } = res["data"]["authorizeDeviceApplication"]
    end
  end
end
