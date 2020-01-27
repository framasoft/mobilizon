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
  # Somehow this can't be merged properly with the dev config some we got this…
  watchers: [
    yarn: [cd: Path.expand("../js", __DIR__)]
  ]

config :mobilizon, sql_sandbox: true

config :mobilizon, Mobilizon.Storage.Repo, pool: Ecto.Adapters.SQL.Sandbox
