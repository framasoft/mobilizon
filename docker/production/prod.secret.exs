# Mobilizon instance configuration

import Config

config :mobilizon, Mobilizon.Web.Endpoint,
   url: [host: System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.lan")],
   http: [port: 4000],
   secret_key_base: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY_BASE", "ZcvexeC7cnwtKR8ADMBDwrYu2aYHUyjrOu4yA181Z112HNu/I5jyRleo4hoxOMqQ")

config :mobilizon, Mobilizon.Web.Auth.Guardian,
  secret_key: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY", "KsdUIvp6hQ7b97yxUZcDQyGH0g4LS3fF0OvIsIATpkKzd1MDvSS4KexWXsjXeMQZ")

config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME", "Mobilizon"),
  description: "Change this to a proper description of your instance",
  hostname: System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.lan"),
  registrations_open: System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_OPEN", "false"),
  demo: false,
  allow_relay: true,
  federating: true,
  email_from: System.get_env("MOBILIZON_INSTANCE_EMAIL", "noreply@mobilizon.lan"),
  email_reply_to: System.get_env("MOBILIZON_INSTANCE_EMAIL", "noreply@mobilizon.lan")

config :mobilizon, Mobilizon.Storage.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME", "username"),
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD", "password"),
  database: System.get_env("MOBILIZON_DATABASE_DBNAME", "mobilizon"),
  hostname: System.get_env("MOBILIZON_DATABASE_HOST", "postgres"),
  port: "5432",
  pool_size: 10

config :mobilizon, Mobilizon.Web.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: System.get_env("MOBILIZON_SMPT_SERVER", "localhost"),
  hostname: System.get_env("MOBILIZON_SMPT_HOSTNAME", "localhost"),
  port: System.get_env("MOBILIZON_SMPT_PORT", "25"),
  username: System.get_env("MOBILIZON_SMPT_USERNAME", nil),
  password: System.get_env("MOBILIZON_SMPT_PASSWORD", nil),
  # can be `:always` or `:never`
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  # can be `true`
  ssl: System.get_env("MOBILIZON_SMPT_SSL", "false"),
  retries: 1,
  # can be `true`
  no_mx_lookups: false,
  # can be `:always`. If your smtp relay requires authentication set it to `:always`.
  auth: :if_available
