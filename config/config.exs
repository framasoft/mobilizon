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

config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME") || "My Mobilizon Instance",
  description:
    System.get_env("MOBILIZON_INSTANCE_DESCRIPTION") ||
      "Change this to a proper description of your instance",
  hostname: System.get_env("MOBILIZON_INSTANCE_HOST") || "localhost",
  registrations_open: System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_OPEN") || false,
  registration_email_whitelist: [],
  demo: System.get_env("MOBILIZON_INSTANCE_DEMO_MODE") || false,
  repository: Mix.Project.config()[:source_url],
  allow_relay: true,
  # Federation is to be activated with Mobilizon 1.0.0-beta.2
  federating: true,
  remote_limit: 100_000,
  upload_limit: 10_000_000,
  avatar_upload_limit: 2_000_000,
  banner_upload_limit: 4_000_000,
  email_from: System.get_env("MOBILIZON_INSTANCE_EMAIL") || "noreply@localhost",
  email_reply_to: System.get_env("MOBILIZON_INSTANCE_EMAIL") || "noreply@localhost"

config :mime, :types, %{
  "application/activity+json" => ["activity-json"],
  "application/jrd+json" => ["jrd-json"]
}

# Configures the endpoint
config :mobilizon, MobilizonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1yOazsoE0Wqu4kXk3uC5gu3jDbShOimTCzyFL3OjCdBmOXMyHX87Qmf3+Tu9s0iM",
  render_errors: [view: MobilizonWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mobilizon.PubSub, adapter: Phoenix.PubSub.PG2]

# Upload configuration
config :mobilizon, MobilizonWeb.Upload,
  uploader: MobilizonWeb.Upload.Uploader.Local,
  filters: [
    MobilizonWeb.Upload.Filter.Dedupe,
    MobilizonWeb.Upload.Filter.Optimize
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

config :mobilizon, MobilizonWeb.Upload.Uploader.Local, uploads: "uploads"

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

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mobilizon, MobilizonWeb.Auth.Guardian,
  issuer: "mobilizon",
  secret_key: "ty0WM7YBE3ojvxoUQxo8AERrNpfbXnIJ82ovkPdqbUFw31T5LcK8wGjaOiReVQjo"

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
      source: System.get_env("GEOLITE_CITIES_PATH") || "priv/data/GeoLite2-City.mmdb"
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

config :mobilizon, :activitypub, sign_object_fetches: true

config :mobilizon, Mobilizon.Service.Geospatial.Nominatim,
  endpoint:
    System.get_env("GEOSPATIAL_NOMINATIM_ENDPOINT") || "https://nominatim.openstreetmap.org",
  api_key: System.get_env("GEOSPATIAL_NOMINATIM_API_KEY") || nil

config :mobilizon, Mobilizon.Service.Geospatial.Addok,
  endpoint: System.get_env("GEOSPATIAL_ADDOK_ENDPOINT") || "https://api-adresse.data.gouv.fr"

config :mobilizon, Mobilizon.Service.Geospatial.Photon,
  endpoint: System.get_env("GEOSPATIAL_PHOTON_ENDPOINT") || "https://photon.komoot.de"

config :mobilizon, Mobilizon.Service.Geospatial.GoogleMaps,
  api_key: System.get_env("GEOSPATIAL_GOOGLE_MAPS_API_KEY") || nil,
  fetch_place_details: System.get_env("GEOSPATIAL_GOOGLE_MAPS_FETCH_PLACE_DETAILS") || true

config :mobilizon, Mobilizon.Service.Geospatial.MapQuest,
  api_key: System.get_env("GEOSPATIAL_MAP_QUEST_API_KEY") || nil

config :mobilizon, Mobilizon.Service.Geospatial.Mimirsbrunn,
  endpoint: System.get_env("GEOSPATIAL_MIMIRSBRUNN_ENDPOINT") || nil

config :mobilizon, Mobilizon.Service.Geospatial.Pelias,
  endpoint: System.get_env("GEOSPATIAL_PELIAS_ENDPOINT") || nil

config :mobilizon, :maps,
  tiles: [
    endpoint:
      System.get_env("MAPS_TILES_ENDPOINT") ||
        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: System.get_env("MAPS_TILES_ATTRIBUTION")
  ]

config :mobilizon, Oban,
  repo: Mobilizon.Storage.Repo,
  prune: {:maxlen, 10_000},
  queues: [default: 10, search: 20, background: 5]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
