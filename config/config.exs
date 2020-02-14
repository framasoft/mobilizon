# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :mobilizon,
  ecto_repos: [Mobilizon.Storage.Repo],
  env: Mix.env()

config :mobilizon, Mobilizon.Storage.Repo, types: Mobilizon.Storage.PostgresTypes

config :mobilizon, :instance,
  name: "My Mobilizon Instance",
  description: "Change this to a proper description of your instance",
  hostname: "localhost",
  registrations_open: false,
  registration_email_whitelist: [],
  demo: false,
  repository: Mix.Project.config()[:source_url],
  allow_relay: true,
  # Federation is to be activated with Mobilizon 1.0.0-beta.2
  federating: true,
  remote_limit: 100_000,
  upload_limit: 10_000_000,
  avatar_upload_limit: 2_000_000,
  banner_upload_limit: 4_000_000,
  email_from: "noreply@localhost",
  email_reply_to: "noreply@localhost"

config :mime, :types, %{
  "application/activity+json" => ["activity-json"],
  "application/jrd+json" => ["jrd-json"]
}

# Configures the endpoint
config :mobilizon, Mobilizon.Web.Endpoint,
  http: [
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [
    host: "mobilizon.local",
    scheme: "https"
  ],
  secret_key_base: "1yOazsoE0Wqu4kXk3uC5gu3jDbShOimTCzyFL3OjCdBmOXMyHX87Qmf3+Tu9s0iM",
  render_errors: [view: Mobilizon.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mobilizon.PubSub, adapter: Phoenix.PubSub.PG2],
  cache_static_manifest: "priv/static/manifest.json"

# Upload configuration
config :mobilizon, Mobilizon.Web.Upload,
  uploader: Mobilizon.Web.Upload.Uploader.Local,
  filters: [
    Mobilizon.Web.Upload.Filter.Dedupe,
    Mobilizon.Web.Upload.Filter.Optimize
  ],
  link_name: true,
  proxy_remote: false,
  proxy_opts: [
    redirect_on_failure: false,
    max_body_length: 25 * 1_048_576,
    http: [
      follow_redirect: true,
      pool: :upload
    ]
  ]

config :mobilizon, Mobilizon.Web.Upload.Uploader.Local, uploads: "uploads"

config :mobilizon, :media_proxy,
  enabled: true,
  proxy_opts: [
    redirect_on_failure: false,
    max_body_length: 25 * 1_048_576,
    http: [
      follow_redirect: true,
      pool: :media
    ]
  ]

config :mobilizon, Mobilizon.Web.Email.Mailer,
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

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mobilizon, Mobilizon.Web.Auth.Guardian, issuer: "mobilizon"

config :guardian, Guardian.DB,
  repo: Mobilizon.Storage.Repo,
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
      source: "priv/data/GeoLite2-City.mmdb"
    }
  ]

config :auto_linker,
  opts: [
    scheme: true,
    extra: true,
    # TODO: Set to :no_scheme when it works properly
    validate_tld: true,
    class: false,
    strip_prefix: false,
    new_window: true,
    rel: "noopener noreferrer ugc"
  ]

config :phoenix, :format_encoders, json: Jason, "activity-json": Jason
config :phoenix, :json_library, Jason

config :ex_cldr,
  default_locale: "en",
  default_backend: Mobilizon.Cldr

config :http_signatures,
  adapter: Mobilizon.Federation.HTTPSignatures.Signature

config :mobilizon, :activitypub,
  # One day
  actor_stale_period: 3_600 * 48,
  actor_key_rotation_delay: 3_600 * 48,
  sign_object_fetches: true

config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Nominatim

config :mobilizon, Mobilizon.Service.Geospatial.Nominatim,
  endpoint: "https://nominatim.openstreetmap.org",
  api_key: nil

config :mobilizon, Mobilizon.Service.Geospatial.Addok,
  endpoint: "https://api-adresse.data.gouv.fr"

config :mobilizon, Mobilizon.Service.Geospatial.Photon, endpoint: "https://photon.komoot.de"

config :mobilizon, Mobilizon.Service.Geospatial.GoogleMaps,
  api_key: nil,
  fetch_place_details: true

config :mobilizon, Mobilizon.Service.Geospatial.MapQuest, api_key: nil

config :mobilizon, Mobilizon.Service.Geospatial.Mimirsbrunn, endpoint: nil

config :mobilizon, Mobilizon.Service.Geospatial.Pelias, endpoint: nil

config :mobilizon, :maps,
  tiles: [
    endpoint: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: "© The OpenStreetMap Contributors"
  ]

config :mobilizon, :anonymous,
  participation: [
    allowed: true,
    validation: %{
      email: [
        enabled: true,
        confirmation_required: true
      ],
      captcha: [enabled: false]
    }
  ],
  event_creation: [
    allowed: false,
    validation: %{
      email: [
        enabled: true,
        confirmation_required: true
      ],
      captcha: [enabled: false]
    }
  ]

config :mobilizon, Oban,
  repo: Mobilizon.Storage.Repo,
  prune: {:maxlen, 10_000},
  queues: [default: 10, search: 20, background: 5]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
