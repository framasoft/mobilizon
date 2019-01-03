use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mobilizon, MobilizonWeb.Endpoint,
  http: [
    port: System.get_env("MOBILIZON_INSTANCE_PORT") || 4002
  ],
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST") || "mobilizon.test",
    port: System.get_env("MOBILIZON_INSTANCE_PORT") || 4002
  ],
  server: false

# Print only warnings and errors during test
config :logger,
  backends: [:console],
  compile_time_purge_level: :debug,
  level: :info

# Configure your database
config :mobilizon, Mobilizon.Repo,
  adapter: Ecto.Adapters.Postgres,
  types: Mobilizon.PostgresTypes,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME") || "mobilizon",
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD") || "mobilizon",
  database: System.get_env("MOBILIZON_DATABASE_DBNAME") || "mobilizon_test",
  hostname: System.get_env("MOBILIZON_DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Mobilizon.PostgresTypes

config :mobilizon, Mobilizon.Mailer, adapter: Bamboo.TestAdapter

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"
