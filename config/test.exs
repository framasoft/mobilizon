use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :eventos, EventosWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger,
   backends: [:console],
   compile_time_purge_level: :debug,
   level: :info

# Configure your database
config :eventos, Eventos.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "elixir",
  password: "elixir",
  database: "eventos_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Eventos.PostgresTypes
