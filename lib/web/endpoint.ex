defmodule Mobilizon.Web.Endpoint do
  @moduledoc """
  Endpoint for Mobilizon app
  """
  use Phoenix.Endpoint, otp_app: :mobilizon
  use Absinthe.Phoenix.Endpoint

  # For e2e tests
  if Application.get_env(:mobilizon, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox,
      at: "/sandbox",
      header: "x-session-id",
      repo: Mobilizon.Storage.Repo
    )
  end

  socket("/graphql_socket", Mobilizon.Web.GraphQLSocket,
    websocket: true,
    longpoll: false
  )

  plug(Mobilizon.Web.Plugs.UploadedMedia)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: {:mobilizon, "priv/static"},
    gzip: false,
    only:
      ~w(index.html manifest.json service-worker.js css fonts images js favicon.ico robots.txt),
    only_matching: ["precache-manifest"]
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
    parsers: [:urlencoded, {:multipart, length: 10_000_000}, :json, Absinthe.Plug.Parser],
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

  plug(Mobilizon.Web.Router)
end
