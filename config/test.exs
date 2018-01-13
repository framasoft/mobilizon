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
  username: if(System.get_env("CI"), do: System.get_env("POSTGRES_USER"), else: "elixir"),
  password: if(System.get_env("CI"), do: System.get_env("POSTGRES_PASSWORD"), else: "elixir"),
  database: "eventos_test",
  hostname: if(System.get_env("CI"), do: "postgres", else: "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Eventos.PostgresTypes
