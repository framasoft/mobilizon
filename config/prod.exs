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
    "bn",
    "ca",
    "cs",
    "cy",
    "de",
    "en",
    "es",
    "fa",
    "fi",
    "fr",
    "gd",
    "gl",
    "hu",
    "id",
    "it",
    "ja",
    "nl",
    "nn",
    "oc",
    "pl",
    "pt",
    "ru",
    "sv",
    "zh_Hant"
  ]
