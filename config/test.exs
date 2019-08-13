use Mix.Config

config :mobilizon, :instance,
  name: "Test instance",
  registrations_open: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mobilizon, MobilizonWeb.Endpoint,
  http: [
    port: System.get_env("MOBILIZON_INSTANCE_PORT") || 80
  ],
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST") || "mobilizon.test"
  ],
  server: false

# Print only warnings and errors during test
config :logger,
  backends: [:console],
  compile_time_purge_level: :debug,
  level: :info

# Configure your database
config :mobilizon, Mobilizon.Repo,
  types: Mobilizon.PostgresTypes,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME") || "mobilizon",
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD") || "mobilizon",
  database: System.get_env("MOBILIZON_DATABASE_DBNAME") || "mobilizon_test",
  hostname: System.get_env("MOBILIZON_DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Mobilizon.PostgresTypes

config :mobilizon, Mobilizon.Mailer, adapter: Bamboo.TestAdapter

config :mobilizon, MobilizonWeb.Upload, filters: [], link_name: false

config :mobilizon, MobilizonWeb.Uploaders.Local, uploads: "test/uploads"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Mock
