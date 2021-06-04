import Config

config :mobilizon, :instance,
  name: "Test instance",
  registrations_open: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mobilizon, Mobilizon.Web.Endpoint,
  http: [
    port: 80
  ],
  url: [
    host: "mobilizon.test",
    scheme: "http"
  ],
  debug_errors: true,
  secret_key_base: "some secret",
  server: false

# Print only warnings and errors during test
config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ],
  level: :info

# Configure your database
config :mobilizon, Mobilizon.Storage.Repo,
  types: Mobilizon.Storage.PostgresTypes,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME") || "mobilizon_test",
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD") || "mobilizon",
  database: System.get_env("MOBILIZON_DATABASE_DBNAME") || "mobilizon_test",
  hostname: System.get_env("MOBILIZON_DATABASE_HOST") || "localhost",
  port: System.get_env("MOBILIZON_DATABASE_PORT") || "5432",
  pool: Ecto.Adapters.SQL.Sandbox

config :mobilizon, :ldap,
  enabled: System.get_env("LDAP_ENABLED") == "true",
  host: System.get_env("LDAP_HOST") || "localhost",
  port: String.to_integer(System.get_env("LDAP_PORT") || "389"),
  ssl: System.get_env("LDAP_SSL") == "true",
  sslopts: [],
  tls: System.get_env("LDAP_TLS") == "true",
  tlsopts: [],
  base: System.get_env("LDAP_BASE") || "dc=example,dc=com",
  uid: System.get_env("LDAP_UID") || "cn",
  require_bind_for_search: !(System.get_env("LDAP_REQUIRE_BIND_FOR_SEARCH") == "false"),
  # The full CN to filter by `memberOf`, or `false` if disabled
  group: false,
  # Either the admin UID matching the field in `uid`,
  # Either a tuple with the fully qualified DN: {:full, uid=admin,dc=example.com,dc=local}
  bind_uid: System.get_env("LDAP_BIND_UID"),
  bind_password: System.get_env("LDAP_BIND_PASSWORD")

config :mobilizon, Mobilizon.Web.Email.Mailer, adapter: Bamboo.TestAdapter

config :mobilizon, Mobilizon.Web.Upload, filters: [], link_name: false

config :mobilizon, Mobilizon.Web.Upload.Uploader.Local, uploads: "test/uploads"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

config :tesla, Mobilizon.Service.HTTP.ActivityPub,
  adapter: Mobilizon.Service.HTTP.ActivityPub.Mock

config :tesla, Mobilizon.Service.HTTP.GeospatialClient,
  adapter: Mobilizon.Service.HTTP.GeospatialClient.Mock

config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Mock

config :mobilizon, Oban, queues: false, plugins: false

config :mobilizon, Mobilizon.Web.Auth.Guardian, secret_key: "some secret"

config :mobilizon, :activitypub, sign_object_fetches: false

config :junit_formatter, report_dir: "."

if System.get_env("DOCKER", "false") == "false" && File.exists?("./config/test.secret.exs") do
  import_config "test.secret.exs"
end
