use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mobilizon, MobilizonWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger,
  backends: [:console],
  compile_time_purge_level: :debug,
  level: :info

# Configure your database
config :mobilizon, Mobilizon.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER") || "elixir",
  password: System.get_env("POSTGRES_PASSWORD") || "elixir",
  database: "mobilizon_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Mobilizon.PostgresTypes

config :mobilizon, Mobilizon.Mailer, adapter: Bamboo.TestAdapter
