defmodule MobilizonWeb.Endpoint do
  @moduledoc """
  Endpoint for Mobilizon app
  """
  use Phoenix.Endpoint, otp_app: :mobilizon

  # For e2e tests
  if Application.get_env(:mobilizon, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox,
      at: "/sandbox",
      header: "x-session-id",
      repo: Mobilizon.Storage.Repo
    )
  end

  plug(MobilizonWeb.Plugs.UploadedMedia)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :mobilizon,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(CORSPlug)
  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_mobilizon_key",
    signing_salt: "F9CCTF22"
  )

  plug(MobilizonWeb.Router)
end
