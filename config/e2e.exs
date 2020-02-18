import Config

import_config "dev.exs"

config :mobilizon, Mobilizon.Web.Endpoint,
  http: [
    port: 4000
  ],
  url: [
    host: "localhost",
    port: 4000,
    scheme: "http"
  ],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  # Somehow this can't be merged properly with the dev config so we got this…
  watchers: [
    yarn: [cd: Path.expand("../js", __DIR__)]
  ]

require Logger

cond do
  System.get_env("INSTANCE_CONFIG") &&
      File.exists?("./config/#{System.get_env("INSTANCE_CONFIG")}") ->
    import_config System.get_env("INSTANCE_CONFIG")

  System.get_env("DOCKER", "false") == "false" && File.exists?("./config/e2e.secret.exs") ->
    import_config "e2e.secret.exs"

  System.get_env("DOCKER", "false") == "true" ->
    Logger.info("Using environment configuration for Docker")

  true ->
    Logger.error("No configuration file found")
end
