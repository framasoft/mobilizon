defmodule Mobilizon.Web.ApplicationControllerTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Service.Auth.Applications
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Factory

  describe "create application" do
    test "requires all parameters",
         %{conn: conn} do
      conn =
        conn
        |> post("/apps", %{"name" => "hello"})

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_request"

      assert error["error_description"] ==
               "All of name, scope and redirect_uri parameters are required to create an application"
    end

    test "requires valid scopes",
         %{conn: conn} do
      conn =
        conn
        |> post("/apps", %{
          "name" => "hello",
          "redirect_uri" => "hello",
          "scope" => "write nothing"
        })

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_scope"

      assert error["error_description"] ==
               "The scope parameter is not a space separated list of valid scopes"
    end

    test "works",
         %{conn: conn} do
      name = "hello"
      redirect_uris = ["hello", "world"]
      scope = "read write:event:create"
      website = "hi"

      conn =
        conn
        |> post("/apps", %{
          "name" => name,
          "redirect_uri" => Enum.join(redirect_uris, "\n"),
          "scope" => scope,
          "website" => website
        })

      assert %{
               "name" => ^name,
               "redirect_uri" => ^redirect_uris,
               "scope" => ^scope,
               "website" => ^website,
               "client_id" => _client_id,
               "client_secret" => _client_secret
             } = json_response(conn, 200)
    end
  end

  describe "authorize" do
    test "without a valid URI", %{conn: conn} do
      conn = get(conn, "/oauth/authorize?client_id=hello&redirect_uri=toto")

      assert response(conn, 400) ==
               "You need to provide a valid redirect_uri to autorize an application"
    end

    test "without all valid params", %{conn: conn} do
      conn =
        get(
          conn,
          "/oauth/authorize?client_id=hello&redirect_uri=#{URI.encode("https://somewhere.org/callback")}"
        )

      assert redirected_to(conn) =~
               "error=invalid_request&error_description=#{URI.encode_www_form("You need to specify client_id, redirect_uri, scope and state to autorize an application")}"
    end

    test "with all required params redirects to authorization page", %{conn: conn} do
      conn =
        get(
          conn,
          "/oauth/authorize?client_id=hello&redirect_uri=#{URI.encode("https://somewhere.org/callback&state=something&scope=everything")}"
        )

      assert redirected_to(conn) =~ "/oauth/autorize_approve"
    end
  end

  describe "generate device code" do
    test "without all required params", %{conn: conn} do
      conn = post(conn, "/login/device/code", client_id: "hello")

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_request"

      assert error["error_description"] ==
               "You need to pass both client_id and scope as parameters to obtain a device code"
    end

    test "with an invalid client_id", %{conn: conn} do
      conn = post(conn, "/login/device/code", client_id: "hello", scope: "write:event:create")

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_client"
      assert error["error_description"] == "No application was found with this client_id"
    end

    test "with a scope not matching app registered scopes", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      conn =
        post(conn, "/login/device/code", client_id: app.client_id, scope: "write:event:delete")

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_scope"

      assert error["error_description"] ==
               "The given scope is not in the list of the app declared scopes"
    end

    test "with valid params gives a URL-encoded code", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      conn =
        post(conn, "/login/device/code", client_id: app.client_id, scope: "write:event:create")

      res = json_response(conn, 200)

      verification_uri = Routes.page_url(Mobilizon.Web.Endpoint, :auth_device)

      assert %{
               "device_code" => _device_code,
               "expires_in" => 900,
               "interval" => 5,
               "user_code" => user_code,
               "verification_uri" => ^verification_uri
             } = res

      assert Regex.match?(~r/^[A-Z]{4}-[A-Z]{4}$/, user_code)
    end

    test "with valid params and a JSON Accept header gives a JSON-encoded struct", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      conn =
        conn
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> post("/login/device/code", client_id: app.client_id, scope: "write:event:create")

      res = json_response(conn, 200)

      verification_uri = Routes.page_url(Mobilizon.Web.Endpoint, :auth_device)

      assert %{
               "device_code" => _device_code,
               "expires_in" => 900,
               "interval" => 5,
               "user_code" => user_code,
               "verification_uri" => ^verification_uri
             } = res

      assert Regex.match?(~r/^[A-Z]{4}-[A-Z]{4}$/, user_code)
    end
  end

  describe "generate access code for device flow" do
    test "without valid parameters", %{conn: conn} do
      conn = post(conn, "/oauth/token")

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_request"

      assert error["error_description"] ==
               "Incorrect parameters sent. You need to provide at least the grant_type and client_id parameters, depending on the grant type being used."
    end

    test "with invalid client_id", %{conn: conn} do
      conn =
        post(conn, "/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: "some_client_id",
          device_code: "hello"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_grant"

      assert error["error_description"] ==
               "The client_id provided or the device_code associated is invalid"
    end

    test "with rejected authorization", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      assert {:ok, _res} =
               Mobilizon.Applications.create_application_device_activation(%{
                 device_code: "hello",
                 user_code: "world",
                 expires_in: 900,
                 application_id: app.id,
                 scope: "write:event:create write:event:update",
                 status: :access_denied
               })

      conn =
        post(conn, "/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "access_denied"
      assert error["error_description"] == "The user rejected the requested authorization"
    end

    test "with incorrect device code", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      assert {:ok, _res} =
               Mobilizon.Applications.create_application_device_activation(%{
                 device_code: "hello",
                 user_code: "world",
                 expires_in: 900,
                 application_id: app.id,
                 scope: "write:event:create write:event:update",
                 status: "incorrect_device_code"
               })

      conn =
        post(conn, "/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_grant"

      assert error["error_description"] ==
               "The client_id provided or the device_code associated is invalid"
    end

    test "with an expired device activation", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      assert {:ok, _res} =
               Mobilizon.Applications.create_application_device_activation(%{
                 device_code: "hello",
                 user_code: "world",
                 expires_in: -40,
                 application_id: app.id,
                 scope: "write:event:create write:event:update",
                 status: "success",
                 user_id: user.id
               })

      conn =
        post(conn, "/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "expired_token"

      assert error["error_description"] ==
               "The given device_code has expired"
    end

    test "with a pending authorization", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      assert {:ok, _res} =
               Mobilizon.Applications.create_application_device_activation(%{
                 device_code: "hello",
                 user_code: "world",
                 expires_in: 600,
                 application_id: app.id,
                 scope: "write:event:create write:event:update",
                 status: "pending",
                 user_id: user.id
               })

      conn =
        conn
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> post("/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      error = json_response(conn, 400)

      assert error["error"] == "authorization_pending"
      assert error["error_description"] == "The authorization request is still pending"

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> post("/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      error = json_response(conn, 400)

      assert error["error"] == "slow_down"
      assert error["error_description"] == "Please slow down the rate of your requests"
    end

    test "with valid params as JSON", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      assert {:ok, _res} =
               Mobilizon.Applications.create_application_device_activation(%{
                 device_code: "hello",
                 user_code: "world",
                 expires_in: 600,
                 application_id: app.id,
                 scope: "write:event:create write:event:update",
                 status: "success",
                 user_id: user.id
               })

      conn =
        conn
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> post("/oauth/token",
          grant_type: "urn:ietf:params:oauth:grant-type:device_code",
          client_id: app.client_id,
          device_code: "hello"
        )

      res = json_response(conn, 200)

      assert %{
               "access_token" => _access_token,
               "expires_in" => 28_800,
               "refresh_token" => _refresh_token,
               "refresh_token_expires_in" => 15_724_800,
               "scope" => "write:event:create write:event:update",
               "token_type" => "bearer"
             } = res
    end
  end

  describe "generate access code for authorization flow" do
    test "with invalid client_id", %{conn: conn} do
      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: "some_client_id",
          client_secret: "some_client_secret",
          code: "hello",
          redirect_uri: "some redirect uri",
          scope: "hello"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_request"

      assert json_response(conn, 400)["error_description"] ==
               "No application was found with this client_id"
    end

    test "with invalid redirect_uri", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_secret,
          code: "hello",
          redirect_uri: "nope",
          scope: "write:event:create"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_request"

      assert error["error_description"] ==
               "This redirect URI is not allowed"
    end

    test "with invalid code", %{conn: conn} do
      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_secret,
          code: "hello",
          redirect_uri: "hello",
          scope: "write:event:create"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_grant"

      assert error["error_description"] ==
               "The provided code is invalid or expired"
    end

    test "with invalid client secret", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      Mobilizon.Applications.create_application_token(%{
        user_id: user.id,
        application_id: app.id,
        authorization_code: "hi there",
        scope: "write:event:create write:event:update"
      })

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: "not the client secret",
          code: "hi there",
          redirect_uri: "hello",
          scope: "write:event:create write:event:update"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_client"

      assert error["error_description"] ==
               "The provided client_secret is invalid"
    end

    test "with an authorization code matching a different app", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      {:ok, app2} =
        Applications.create("My other app", ["hello"], "write:event:create write:event:update")

      Mobilizon.Applications.create_application_token(%{
        user_id: user.id,
        application_id: app2.id,
        authorization_code: "hi there",
        scope: "write:event:create write:event:update"
      })

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_id,
          code: "hi there",
          redirect_uri: "hello",
          scope: "write:event:create write:event:update"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_grant"

      assert error["error_description"] ==
               "The provided client_id does not match the provided code"
    end

    test "with valid params", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      Mobilizon.Applications.create_application_token(%{
        user_id: user.id,
        application_id: app.id,
        authorization_code: "hi there",
        scope: "write:event:create write:event:update"
      })

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_secret,
          code: "hi there",
          redirect_uri: "hello",
          scope: "write:event:create write:event:update"
        )

      res = json_response(conn, 200)

      assert %{
               "access_token" => _access_token,
               "expires_in" => 28_800,
               "refresh_token" => _refresh_token,
               "refresh_token_expires_in" => 15_724_800,
               "scope" => "write:event:create write:event:update",
               "token_type" => "bearer"
             } = res
    end
  end

  describe "generate new access code from refresh code" do
    test "with invalid refresh token", %{conn: conn} do
      conn =
        post(conn, "/oauth/token",
          grant_type: "refresh_token",
          client_id: "hello",
          client_secret: "secret",
          refresh_token: "none"
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_grant"

      assert error["error_description"] ==
               "Invalid refresh token provided"
    end

    test "with invalid client credentials", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      Mobilizon.Applications.create_application_token(%{
        user_id: user.id,
        application_id: app.id,
        authorization_code: "hi there",
        scope: "write:event:create write:event:update"
      })

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_secret,
          code: "hi there",
          redirect_uri: "hello",
          scope: "write:event:create write:event:update"
        )

      res = json_response(conn, 200)

      conn =
        post(conn, "/oauth/token",
          grant_type: "refresh_token",
          client_id: "hello",
          client_secret: "secret",
          refresh_token: res["refresh_token"]
        )

      assert error = json_response(conn, 400)
      assert error["error"] == "invalid_client"

      assert error["error_description"] ==
               "Invalid client credentials provided"
    end

    test "with valid params", %{conn: conn} do
      user = insert(:user)

      {:ok, app} =
        Applications.create("My app", ["hello"], "write:event:create write:event:update")

      Mobilizon.Applications.create_application_token(%{
        user_id: user.id,
        application_id: app.id,
        authorization_code: "hi there",
        scope: "write:event:create write:event:update"
      })

      conn =
        post(conn, "/oauth/token",
          grant_type: "authorization_code",
          client_id: app.client_id,
          client_secret: app.client_secret,
          code: "hi there",
          redirect_uri: "hello",
          scope: "write:event:create write:event:update"
        )

      res = json_response(conn, 200)

      conn =
        post(conn, "/oauth/token",
          grant_type: "refresh_token",
          client_id: app.client_id,
          client_secret: app.client_secret,
          refresh_token: res["refresh_token"]
        )

      res = json_response(conn, 200)

      assert %{
               "access_token" => _access_token,
               "expires_in" => 28_800,
               "refresh_token" => _refresh_token,
               "refresh_token_expires_in" => 15_724_800,
               "scope" => "write:event:create write:event:update",
               "token_type" => "bearer"
             } = res
    end
  end
end
