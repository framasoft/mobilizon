defmodule Mobilizon.Web.Endpoint do
  @moduledoc """
  Endpoint for Mobilizon app
  """

  if Application.compile_env(:mobilizon, :env) !== :test do
    use Sentry.PlugCapture
  end

  use Phoenix.Endpoint, otp_app: :mobilizon
  use Absinthe.Phoenix.Endpoint

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: {:mobilizon, "priv/static"},
    gzip: false,
    only: Mobilizon.Web.static_paths()
    # only_matching: ["precache-manifest"]
  )

  plug(Mobilizon.Web.Plugs.UploadedMedia)

  plug(Mobilizon.Web.Plugs.DetectLocalePlug)

  if Application.compile_env(:mobilizon, :env) !== :dev do
    plug(Mobilizon.Web.Plugs.HTTPSecurityPlug)
  end

  # For e2e tests
  # if Application.get_env(:mobilizon, :sql_sandbox) do
  #   plug(Phoenix.Ecto.SQL.Sandbox,
  #     at: "/sandbox",
  #     header: "x-session-id",
  #     repo: Mobilizon.Storage.Repo
  #   )
  # end

  socket("/graphql_socket", Mobilizon.Web.GraphQLSocket,
    websocket: true,
    longpoll: false
  )

  plug(Unplug,
    if:
      {Mobilizon.Service.UnplugPredicates.AppConfigKeywordEquals,
       {:mobilizon, Mobilizon.Web.Endpoint, :has_reverse_proxy, false, true}},
    do: RemoteIp
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

  plug(Replug,
    plug: {Plug.Parsers, pass: ["*/*"], json_decoder: Jason},
    opts: {Mobilizon.Web.PlugConfigs, :parsers}
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Mobilizon.Web.Router)

  @spec websocket_url :: String.t()
  def websocket_url do
    String.replace_leading(url(), "http", "ws")
  end

  if Application.compile_env(:mobilizon, :env) !== :test do
    plug(Sentry.PlugContext)
  end
end
