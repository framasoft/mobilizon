defmodule Mobilizon.Web.AuthController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  require Logger
  plug(:put_layout, false)

  plug(Ueberauth)

  def request(conn, %{"provider" => provider_name} = _params) do
    case provider_config(provider_name) do
      {:ok, provider_config} ->
        conn
        |> Ueberauth.run_request(provider_name, provider_config)

      {:error, error} ->
        redirect_to_error(conn, error, provider_name)
    end
  end

  def callback(
        %{assigns: %{ueberauth_failure: fails}} = conn,
        %{"provider" => provider} = _params
      ) do
    Logger.warn("Unable to login user with #{provider} #{inspect(fails)}")

    redirect_to_error(conn, :unknown_error, provider)
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{strategy: strategy} = auth}} = conn,
        _params
      ) do
    email = email_from_ueberauth(auth)
    [_, _, _, strategy] = strategy |> to_string() |> String.split(".")
    strategy = String.downcase(strategy)

    user =
      with {:valid_email, false} <- {:valid_email, is_nil(email) or email == ""},
           {:error, :user_not_found} <- Users.get_user_by_email(email),
           {:ok, %User{} = user} <- Users.create_external(email, strategy) do
        user
      else
        {:ok, %User{} = user} ->
          user

        {:error, error} ->
          {:error, error}

        error ->
          {:error, error}
      end

    with %User{} = user <- user,
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Authenticator.generate_tokens(user) do
      Logger.info("Logged-in user \"#{email}\" through #{strategy}")

      render(conn, "callback.html", %{
        access_token: access_token,
        refresh_token: refresh_token,
        user: user
      })
    else
      err ->
        Logger.warn("Unable to login user \"#{email}\" #{inspect(err)}")
        redirect_to_error(conn, :unknown_error, strategy)
    end
  end

  def callback(conn, %{"provider" => provider_name} = params) do
    case provider_config(provider_name) do
      {:ok, provider_config} ->
        conn
        |> Ueberauth.run_callback(provider_name, provider_config)
        |> callback(params)

      {:error, error} ->
        redirect_to_error(conn, error, provider_name)
    end
  end

  # Github only give public emails as part of the user profile,
  # so we explicitely request all user emails and filter on the primary one
  defp email_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.Github,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"emails" => emails}}}
       })
       when length(emails) > 0,
       do: emails |> Enum.find(& &1["primary"]) |> (& &1["email"]).()

  defp email_from_ueberauth(%Ueberauth.Auth{
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => email}}}
       })
       when not is_nil(email) and email != "",
       do: email

  defp email_from_ueberauth(_), do: nil

  defp provider_config(provider_name) do
    with ueberauth when is_list(ueberauth) <- Application.get_env(:ueberauth, Ueberauth),
         providers when is_list(providers) <- Keyword.get(ueberauth, :providers),
         providers_keys <- providers |> Keyword.keys() |> Enum.map(&Atom.to_string/1),
         {:supported, true} <- {:supported, provider_name in providers_keys},
         provider_name <- String.to_existing_atom(provider_name),
         provider_config <- Keyword.get(providers, provider_name) do
      {:ok, provider_config}
    else
      {:supported, false} ->
        {:error, :not_supported}

      _ ->
        {:error, :unknown_error}
    end
  end

  @spec redirect_to_error(Plug.Conn.t(), atom(), String.t()) :: Plug.Conn.t()
  defp redirect_to_error(conn, :not_supported, provider_name) do
    redirect(conn, to: "/login?code=Login Provider not found&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :unknown_error, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end
end
