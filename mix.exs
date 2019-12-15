defmodule Mobilizon.Mixfile do
  use Mix.Project

  @version "1.0.0-beta.1"

  def project do
    [
      app: :mobilizon,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      name: "Mobilizon",
      source_url: "https://framagit.org/framasoft/mobilizon",
      homepage_url: "https://joinmobilizon.org",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Mobilizon, []},
      extra_applications: [:logger, :runtime_tools, :guardian, :bamboo, :geolix, :crypto, :cachex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/factory.ex"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.15.3"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 2.6"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.0.2"},
      {:guardian_phoenix, "~> 2.0"},
      {:argon2_elixir, "~> 2.0"},
      {:cors_plug, "~> 2.0"},
      {:ecto_autoslug_field, "~> 2.0"},
      {:rsa_ex, "~> 0.1"},
      {:geo, "~> 3.0"},
      {:geo_postgis, "~> 3.1"},
      {:timex, "~> 3.0"},
      {:icalendar, github: "tcitworld/icalendar"},
      {:exgravatar, "~> 2.0.1"},
      {:httpoison, "~> 1.0"},
      {:json_ld, "~> 0.3"},
      {:jason, "~> 1.1"},
      {:ex_crypto, "~> 0.10.0"},
      {:http_sign, "~> 0.1.1"},
      {:ecto_enum, "~> 1.4"},
      {:ex_ical, "~> 0.2"},
      {:bamboo, "~> 1.0"},
      {:bamboo_smtp, "~> 2.0"},
      {:geolix, "~> 1.0"},
      {:geolix_adapter_mmdb2, "~> 0.2.0"},
      {:absinthe, "~> 1.4.16"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:absinthe_plug, "~> 1.4.6"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:dataloader, "~> 1.0.6"},
      {:plug_cowboy, "~> 2.0"},
      {:atomex, "0.3.0"},
      {:cachex, "~> 3.1"},
      {:geohax, "~> 0.3.0"},
      {:mogrify, "~> 0.7.2"},
      {:auto_linker,
       git: "https://git.pleroma.social/pleroma/auto_linker.git",
       ref: "95e8188490e97505c56636c1379ffdf036c1fdde"},
      {:http_signatures,
       git: "https://git.pleroma.social/pleroma/http_signatures.git",
       ref: "293d77bb6f4a67ac8bde1428735c3b42f22cbb30"},
      {:html_sanitize_ex, "~> 1.4.0"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:ex_optimizer, "~> 0.1"},
      {:progress_bar, "~> 2.0"},
      {:oban, "~> 0.12.0"},
      # Dev and test dependencies
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :e2e]},
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      {:excoveralls, "~> 0.12.1", only: :test},
      {:ex_doc, "~> 0.21.1", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:exvcr, "~> 0.10", only: :test},
      {:credo, "~> 1.1.2", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.4", only: :test},
      {:elixir_feed_parser, "~> 2.1.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": [
        "ecto.drop",
        "ecto.setup"
      ],
      test: [
        "ecto.migrate",
        &run_test/1
      ],
      "phx.deps_migrate_serve": [
        "deps.get",
        "ecto.create --quiet",
        "ecto.migrate",
        "cmd cd js && yarn install && cd ../",
        "phx.server"
      ]
    ]
  end

  defp run_test(args) do
    Mix.Task.run("test", args)
    File.rm_rf!("test/uploads")
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      groups_for_modules: groups_for_modules(),
      nest_modules_by_prefix: [
        Mobilizon,
        MobilizonWeb,
        Mobilizon.Service.Geospatial,
        MobilizonWeb.Resolvers,
        MobilizonWeb.Schema,
        Mobilizon.Service
      ]
    ]
  end

  defp groups_for_modules() do
    [
      Models: [
        Mobilizon.Actors,
        Mobilizon.Actors.Actor,
        Mobilizon.Actors.ActorOpenness,
        Mobilizon.Actors.ActorType,
        Mobilizon.Actors.MemberRole,
        Mobilizon.Actors.Bot,
        Mobilizon.Actors.Follower,
        Mobilizon.Actors.Member,
        Mobilizon.Addresses,
        Mobilizon.Addresses.Address,
        Mobilizon.Events,
        Mobilizon.Service.ActivityPub.Activity,
        Mobilizon.Events.Event,
        Mobilizon.Events.Comment,
        Mobilizon.Events.FeedToken,
        Mobilizon.Events.Participant,
        Mobilizon.Events.Session,
        Mobilizon.Events.Tag,
        Mobilizon.Events.TagRelations,
        Mobilizon.Events.Track,
        Mobilizon.Event.EventCategory,
        Mobilizon.Events.CommentVisibility,
        Mobilizon.Events.EventStatus,
        Mobilizon.Events.EventVisibility,
        Mobilizon.Events.JoinOptions,
        Mobilizon.Events.ParticipantRole,
        Mobilizon.Events.Tag.TitleSlug,
        Mobilizon.Events.Tag.TitleSlug.Type,
        Mobilizon.Events.TagRelation,
        Mobilizon.Users,
        Mobilizon.Users.User,
        Mobilizon.Users.UserRole,
        Mobilizon.Users.Guards,
        Mobilizon.Storage.Ecto,
        Mobilizon.Storage.Repo
      ],
      APIs: [
        MobilizonWeb.API.Comments,
        MobilizonWeb.API.Events,
        MobilizonWeb.API.Groups,
        MobilizonWeb.API.Search,
        MobilizonWeb.API.Utils
      ],
      Web: [
        MobilizonWeb,
        MobilizonWeb.PageView,
        MobilizonWeb.Router,
        MobilizonWeb.Router.Helpers,
        MobilizonWeb.AuthErrorHandler,
        MobilizonWeb.AuthPipeline,
        MobilizonWeb.Cache,
        MobilizonWeb.ChangesetView,
        MobilizonWeb.Context,
        MobilizonWeb.Endpoint,
        MobilizonWeb.ErrorHelpers,
        MobilizonWeb.ErrorView,
        MobilizonWeb.FallbackController,
        MobilizonWeb.FeedController,
        MobilizonWeb.Gettext,
        MobilizonWeb.Guardian,
        MobilizonWeb.Guardian.Plug,
        MobilizonWeb.JsonLD.ObjectView,
        MobilizonWeb.PageController,
        MobilizonWeb.Uploaders.Avatar,
        MobilizonWeb.Uploaders.Category,
        MobilizonWeb.Uploaders.Category.Type
      ],
      Geospatial: [
        Mobilizon.Service.Geospatial,
        Mobilizon.Service.Geospatial.Addok,
        Mobilizon.Service.Geospatial.GoogleMaps,
        Mobilizon.Service.Geospatial.MapQuest,
        Mobilizon.Service.Geospatial.Nominatim,
        Mobilizon.Service.Geospatial.Photon,
        Mobilizon.Service.Geospatial.Provider
      ],
      GraphQL: [
        MobilizonWeb.Resolvers.Address,
        MobilizonWeb.Resolvers.Comment,
        MobilizonWeb.Resolvers.Event,
        MobilizonWeb.Resolvers.FeedToken,
        MobilizonWeb.Resolvers.Group,
        MobilizonWeb.Resolvers.Person,
        MobilizonWeb.Resolvers.Search,
        MobilizonWeb.Resolvers.Tag,
        MobilizonWeb.Resolvers.User,
        MobilizonWeb.Schema,
        MobilizonWeb.Schema.ActorInterface,
        MobilizonWeb.Schema.Actors.FollowerType,
        MobilizonWeb.Schema.Actors.GroupType,
        MobilizonWeb.Schema.Actors.MemberType,
        MobilizonWeb.Schema.Actors.PersonType,
        MobilizonWeb.Schema.AddressType,
        MobilizonWeb.Schema.CommentType,
        MobilizonWeb.Schema.Custom.Point,
        MobilizonWeb.Schema.Custom.UUID,
        MobilizonWeb.Schema.EventType,
        MobilizonWeb.Schema.Events.FeedTokenType,
        MobilizonWeb.Schema.Events.ParticipantType,
        MobilizonWeb.Schema.SortType,
        MobilizonWeb.Schema.TagType,
        MobilizonWeb.Schema.UserType,
        MobilizonWeb.Schema.Utils
      ],
      ActivityPub: [
        MobilizonWeb.ActivityPub.ActorView,
        MobilizonWeb.ActivityPub.ObjectView,
        MobilizonWeb.ActivityPubController,
        Mobilizon.Service.ActivityPub,
        Mobilizon.Service.ActivityPub.Transmogrifier,
        Mobilizon.Service.ActivityPub.Utils,
        MobilizonWeb.HTTPSignaturePlug,
        MobilizonWeb.WebFingerController,
        MobilizonWeb.NodeInfoController,
        Mobilizon.Service.HTTPSignatures.Signature,
        Mobilizon.Service.WebFinger,
        Mobilizon.Service.XmlBuilder,
        Mobilizon.Service.Federator
      ],
      Services: [
        Mobilizon.Service.EmailChecker,
        Mobilizon.Service.Export.Feed,
        Mobilizon.Service.Export.ICalendar,
        Mobilizon.Service.Metadata,
        Mobilizon.Service.Formatter,
        Mobilizon.Service.Users.Tools
      ],
      Tools: [
        Mobilizon.Application,
        Mobilizon.Factory,
        MobilizonWeb.Email.Mailer,
        MobilizonWeb.Email.User,
        MobilizonWeb.EmailView
      ]
    ]
  end
end
