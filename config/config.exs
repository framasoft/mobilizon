# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mobilizon,
  ecto_repos: [Mobilizon.Repo]

config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME") || "Localhost",
  version: "1.0.0-dev",
  registrations_open: true

config :mime, :types, %{
  "application/activity+json" => ["activity-json"],
  "application/jrd+json" => ["jrd-json"]
}

# Configures the endpoint
config :mobilizon, MobilizonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1yOazsoE0Wqu4kXk3uC5gu3jDbShOimTCzyFL3OjCdBmOXMyHX87Qmf3+Tu9s0iM",
  render_errors: [view: MobilizonWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mobilizon.PubSub, adapter: Phoenix.PubSub.PG2],
  instance: "localhost",
  email_from: "noreply@localhost",
  email_to: "noreply@localhost"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :mobilizon, MobilizonWeb.Guardian,
  issuer: "mobilizon",
  secret_key: "ty0WM7YBE3ojvxoUQxo8AERrNpfbXnIJ82ovkPdqbUFw31T5LcK8wGjaOiReVQjo"

config :guardian, Guardian.DB,
  repo: Mobilizon.Repo,
  # default
  schema_name: "guardian_tokens",
  # store all token types if not set
  # token_types: ["refresh_token"],
  # default: 60 minutes
  sweep_interval: 60

config :geolix,
  databases: [
    %{
      id: :city,
      adapter: Geolix.Adapter.MMDB2,
      source: System.get_env("GEOLITE_CITIES_PATH") || "priv/data/GeoLite2-City.mmdb"
    }
  ]

config :arc,
  storage: Arc.Storage.Local

config :phoenix, :format_encoders, json: Jason
