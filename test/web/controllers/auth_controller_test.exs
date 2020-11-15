defmodule Mobilizon.Web.AuthControllerTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users.User

  @email "someone@somewhere.tld"

  setup do
    Application.put_env(:ueberauth, Ueberauth,
      providers: [twitter: {Ueberauth.Strategy.Twitter, []}]
    )
  end

  test "login and registration",
       %{conn: conn} do
    conn =
      conn
      |> assign(:ueberauth_auth, %Ueberauth.Auth{
        strategy: Ueberauth.Strategy.Twitter,
        extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => @email}}}
      })
      |> get("/auth/twitter/callback")

    assert html_response(conn, 200) =~ "auth-access-token"

    assert %User{confirmed_at: confirmed_at, email: @email} = Authenticator.fetch_user(@email)

    refute is_nil(confirmed_at)
  end

  test "on bad provider error", %{
    conn: conn
  } do
    conn =
      conn
      |> assign(:ueberauth_failure, %{errors: [%{message: "Some error"}]})
      |> get("/auth/nothing")

    assert "/login?code=Login Provider not found&provider=nothing" =
             redirection = redirected_to(conn, 302)

    conn = get(recycle(conn), redirection)
    assert html_response(conn, 200)
  end

  test "on authentication error", %{
    conn: conn
  } do
    conn =
      conn
      |> assign(:ueberauth_failure, %{errors: [%{message: "Some error"}]})
      |> get("/auth/twitter/callback")

    assert "/login?code=Error with Login Provider&provider=twitter" =
             redirection = redirected_to(conn, 302)

    conn = get(recycle(conn), redirection)
    assert html_response(conn, 200)
  end
end
