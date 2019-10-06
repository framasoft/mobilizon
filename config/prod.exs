import Config

config :mobilizon, MobilizonWeb.Endpoint,
  http: [:inet6, port: System.get_env("MOBILIZON_INSTANCE_PORT") || 4000],
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST") || "mobilizon.me",
    port: 443,
    scheme: "https"
  ],
  secret_key_base:
    System.get_env("MOBILIZON_SECRET") || "ThisShouldBeAVeryStrongStringPleaseReplaceMe",
  cache_static_manifest: "priv/static/manifest.json"

# Configure your database
config :mobilizon, Mobilizon.Storage.Repo,
  types: Mobilizon.Storage.PostgresTypes,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME") || "mobilizon",
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD") || "mobilizon",
  database: System.get_env("MOBILIZON_DATABASE_DBNAME") || "mobilizon_prod",
  hostname: System.get_env("MOBILIZON_DATABASE_HOST") || "localhost",
  port: System.get_env("MOBILIZON_DATABASE_PORT") || "5432",
  pool_size: 15

config :mobilizon, MobilizonWeb.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "localhost",
  hostname: "localhost",
  port: 25,
  # or {:system, "SMTP_USERNAME"}
  username: nil,
  # or {:system, "SMTP_PASSWORD"}
  password: nil,
  # can be `:always` or `:never`
  tls: :if_available,
  # or {":system", ALLOWED_TLS_VERSIONS"} w/ comma seprated values (e.g. "tlsv1.1,tlsv1.2")
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  # can be `true`
  ssl: false,
  retries: 1,
  # can be `true`
  no_mx_lookups: false

# Do not print debug messages in production
config :logger, level: System.get_env("MOBILIZON_LOGLEVEL") |> String.to_atom() || :info

config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Nominatim

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :mobilizon, MobilizonWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :mobilizon, MobilizonWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :mobilizon, MobilizonWeb.Endpoint, server: true
#
