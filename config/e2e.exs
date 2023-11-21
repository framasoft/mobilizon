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
    node: [
      "node_modules/.bin/vite"
    ]
  ]

config :vite_phx,
  release_app: :mobilizon,
  # Hard code :prod as an environment as :e2e will not be recongnized
  environment: :prod,
  vite_manifest: "priv/static/manifest.json",
  phx_manifest: "priv/static/cache_manifest.json",
  dev_server_address: "http://localhost:5173"

config :mobilizon, :instance,
  name: "E2E Testing instance",
  description: "E2E is safety",
  hostname: "mobilizon1.com",
  registrations_open: true,
  registration_email_denylist: ["gmail.com", "deny@tcit.fr"],
  demo: false,
  default_language: "en",
  allow_relay: true,
  federating: true,
  email_from: "mobilizon@mobilizon1.com",
  email_reply_to: nil,
  enable_instance_feeds: true,
  koena_connect_link: true,
  extra_categories: [
    %{
      id: :something_else,
      label: "Quelque chose d'autre"
    }
  ]

config :mobilizon, Mobilizon.Storage.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME", "mobilizon_e2e"),
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD", "mobilizon_e2e"),
  database: System.get_env("MOBILIZON_DATABASE_DBNAME", "mobilizon_e2e"),
  hostname: System.get_env("MOBILIZON_DATABASE_HOST", "localhost"),
  port: System.get_env("MOBILIZON_DATABASE_PORT") || "5432"
