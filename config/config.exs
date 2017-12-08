# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :eventos,
  ecto_repos: [Eventos.Repo]

# Configures the endpoint
config :eventos, EventosWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1yOazsoE0Wqu4kXk3uC5gu3jDbShOimTCzyFL3OjCdBmOXMyHX87Qmf3+Tu9s0iM",
  render_errors: [view: EventosWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Eventos.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Eventos.Accounts.User,
  repo: Eventos.Repo,
  module: Eventos,
  web_module: EventosWeb,
  router: EventosWeb.Router,
  messages_backend: EventosWeb.Coherence.Messages,
  logged_out_url: "/",
  user_active_field: true,
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:invitable, :confirmable, :rememberable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :registerable]

config :coherence, EventosWeb.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
# %% End Coherence Configuration %%
