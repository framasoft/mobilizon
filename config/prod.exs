import Config

config :mobilizon, Mobilizon.Web.Endpoint,
  http: [
    port: 4000
  ],
  url: [
    host: "mobilizon.local",
    scheme: "https",
    port: 443
  ]

# Do not print debug messages in production
config :logger, level: :info

# Load all locales in production
config :mobilizon, :cldr,
  locales: [
    "ar",
    "be",
    "ca",
    "cs",
    "de",
    "en",
    "es",
    "fi",
    "fr",
    "gl",
    "hu",
    "it",
    "ja",
    "nl",
    "nn",
    "oc",
    "pl",
    "pt",
    "ru",
    "sv"
  ]

cond do
  System.get_env("INSTANCE_CONFIG") &&
      File.exists?("./config/#{System.get_env("INSTANCE_CONFIG")}") ->
    import_config System.get_env("INSTANCE_CONFIG")

  File.exists?("./config/prod.secret.exs") ->
    import_config "prod.secret.exs"

  true ->
    require Logger
    Logger.error("No configuration file found")
end
