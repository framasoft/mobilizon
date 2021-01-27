defmodule Mobilizon.Mixfile do
  use Mix.Project

  @version "1.0.5"

  def project do
    [
      app: :mobilizon,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      xref: [exclude: [:eldap]],
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
      docs: docs(),
      releases: [
        mobilizon: [
          applications: [eldap: :transient]
        ]
      ]
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

  # Specifies OAuth dependencies.
  defp oauth_deps do
    oauth_strategy_packages =
      System.get_env("OAUTH_CONSUMER_STRATEGIES")
      |> to_string()
      |> String.split()
      |> Enum.map(fn strategy_entry ->
        with [_strategy, dependency] <- String.split(strategy_entry, ":") do
          dependency
        else
          [strategy] -> "ueberauth_#{strategy}"
        end
      end)

    for s <- oauth_strategy_packages, do: {String.to_atom(s), ">= 0.0.0"}
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.15.3"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 2.6"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.1.0"},
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
      # {:json_ld, "~> 0.3"},
      {:jason, "~> 1.2"},
      {:ex_crypto, "~> 0.10.0"},
      {:http_sign, "~> 0.1.1"},
      {:ecto_enum, "~> 1.4"},
      {:ex_ical, "~> 0.2"},
      {:bamboo, "~> 1.5"},
      {:bamboo_smtp, "~> 3.0"},
      {:geolix, "~> 2.0"},
      {:geolix_adapter_mmdb2, "~> 0.6.0"},
      {:absinthe, "~> 1.6"},
      {:absinthe_phoenix,
       github: "absinthe-graphql/absinthe_phoenix",
       ref: "67dc53db5b826ea12f37860bcce4334d4aaad028"},
      {:absinthe_plug, "~> 1.5.0"},
      {:dataloader, "~> 1.0.6"},
      {:plug_cowboy, "~> 2.0"},
      {:atomex, "~> 0.4"},
      {:cachex, "~> 3.1"},
      {:geohax, "~> 0.4.0"},
      {:mogrify, "~> 0.8.0"},
      {:linkify, "~> 0.3"},
      {:http_signatures, "~> 0.1.0"},
      {:ex_cldr, "~> 2.0"},
      {:ex_cldr_dates_times, "~> 2.2"},
      {:ex_optimizer, "~> 0.1"},
      {:progress_bar, "~> 2.0"},
      {:oban, "~> 2.2"},
      {:floki, "~> 0.29.0"},
      {:ip_reserved, "~> 0.1.0"},
      {:fast_sanitize, "~> 0.1"},
      {:ueberauth, "~> 0.6"},
      {:ueberauth_twitter, "~> 0.3"},
      {:ueberauth_github, "~> 0.7"},
      {:ueberauth_facebook, "~> 0.8"},
      {:ueberauth_discord, "~> 0.5"},
      {:ueberauth_google, "~> 0.9"},
      {:ueberauth_keycloak_strategy,
       git: "https://github.com/tcitworld/ueberauth_keycloak.git", branch: "upgrade-deps"},
      {:ueberauth_gitlab_strategy,
       git: "https://github.com/tcitworld/ueberauth_gitlab.git", branch: "upgrade-deps"},
      {:ecto_shortuuid, "~> 0.1"},
      {:tesla, "~> 1.4.0"},
      {:sitemapper, "~> 0.5.0"},
      {:xml_builder, "~> 2.1.1"},
      {:remote_ip, "~> 0.2.0"},
      {:ex_cldr_languages, "~> 0.2.1"},
      {:slugger, "~> 0.3"},
      {:sentry, "~> 7.0"},
      # Dev and test dependencies
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :e2e]},
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      {:excoveralls, "~> 0.13.0", only: :test},
      {:ex_doc, "~> 0.23", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:exvcr, "~> 0.12", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.4", only: :test},
      {:elixir_feed_parser, "~> 2.1.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:sobelow, "~> 0.8", only: [:dev, :test]}
    ] ++ oauth_deps()
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
        "ecto.create",
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
        Mobilizon.Web,
        Mobilizon.Service.Geospatial,
        Mobilizon.Web.Resolvers,
        Mobilizon.GraphQL.Schema,
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
        Mobilizon.Admin,
        Mobilizon.Admin.ActionLog,
        Mobilizon.Events,
        Mobilizon.Events.Event,
        Mobilizon.Events.FeedToken,
        Mobilizon.Events.Participant,
        Mobilizon.Events.Session,
        Mobilizon.Events.Tag,
        Mobilizon.Events.TagRelations,
        Mobilizon.Events.Track,
        Mobilizon.Events.EventCategory,
        Mobilizon.Events.EventStatus,
        Mobilizon.Events.EventVisibility,
        Mobilizon.Events.JoinOptions,
        Mobilizon.Events.ParticipantRole,
        Mobilizon.Events.Tag.TitleSlug,
        Mobilizon.Events.Tag.TitleSlug.Type,
        Mobilizon.Events.TagRelation,
        Mobilizon.Medias,
        Mobilizon.Medias.File,
        Mobilizon.Medias.Media,
        Mobilizon.Mention,
        Mobilizon.Reports,
        Mobilizon.Reports.Note,
        Mobilizon.Reports.Report,
        Mobilizon.Share,
        Mobilizon.Tombstone,
        Mobilizon.Users,
        Mobilizon.Users.User,
        Mobilizon.Users.UserRole,
        Mobilizon.Federation.ActivityPub.Activity
      ],
      APIs: [
        Mobilizon.GraphQL.API.Comments,
        Mobilizon.GraphQL.API.Events,
        Mobilizon.GraphQL.API.Follows,
        Mobilizon.GraphQL.API.Groups,
        Mobilizon.GraphQL.API.Participations,
        Mobilizon.GraphQL.API.Reports,
        Mobilizon.GraphQL.API.Search,
        Mobilizon.GraphQL.API.Utils
      ],
      Web: [
        Mobilizon.Web,
        Mobilizon.Web.Endpoint,
        Mobilizon.Web.Router,
        Mobilizon.Web.Router.Helpers,
        Mobilizon.Web.Plugs.UploadedMedia,
        Mobilizon.Web.FallbackController,
        Mobilizon.Web.FeedController,
        Mobilizon.Web.PageController,
        Mobilizon.Web.ChangesetView,
        Mobilizon.Web.JsonLD.ObjectView,
        Mobilizon.Web.EmailView,
        Mobilizon.Web.ErrorHelpers,
        Mobilizon.Web.ErrorView,
        Mobilizon.Web.LayoutView,
        Mobilizon.Web.PageView,
        Mobilizon.Web.Auth.Context,
        Mobilizon.Web.Auth.ErrorHandler,
        Mobilizon.Web.Auth.Guardian,
        Mobilizon.Web.Auth.Pipeline,
        Mobilizon.Web.Cache,
        Mobilizon.Web.Cache.ActivityPub,
        Mobilizon.Web.Email,
        Mobilizon.Web.Email.Admin,
        Mobilizon.Web.Email.Checker,
        Mobilizon.Web.Email.Event,
        Mobilizon.Web.Email.Mailer,
        Mobilizon.Web.Email.Participation,
        Mobilizon.Web.Email.User,
        Mobilizon.Web.Upload,
        Mobilizon.Web.Upload.Filter,
        Mobilizon.Web.Upload.Filter.AnonymizeFilename,
        Mobilizon.Web.Upload.Filter.Dedupe,
        Mobilizon.Web.Upload.Filter.Mogrify,
        Mobilizon.Web.Upload.Filter.Optimize,
        Mobilizon.Web.Upload.MIME,
        Mobilizon.Web.Upload.Uploader,
        Mobilizon.Web.Upload.Uploader.Local,
        Mobilizon.Web.ReverseProxy
      ],
      Geospatial: [
        Mobilizon.Service.Geospatial,
        Mobilizon.Service.Geospatial.Addok,
        Mobilizon.Service.Geospatial.GoogleMaps,
        Mobilizon.Service.Geospatial.MapQuest,
        Mobilizon.Service.Geospatial.Mimirsbrunn,
        Mobilizon.Service.Geospatial.Nominatim,
        Mobilizon.Service.Geospatial.Pelias,
        Mobilizon.Service.Geospatial.Photon,
        Mobilizon.Service.Geospatial.Provider
      ],
      Localization: [
        Mobilizon.Cldr,
        Mobilizon.Web.Gettext
      ],
      GraphQL: [
        Mobilizon.Web.GraphQLSocket,
        Mobilizon.GraphQL.Resolvers.Address,
        Mobilizon.GraphQL.Resolvers.Admin,
        Mobilizon.GraphQL.Resolvers.Comment,
        Mobilizon.GraphQL.Resolvers.Config,
        Mobilizon.GraphQL.Resolvers.Event,
        Mobilizon.GraphQL.Resolvers.FeedToken,
        Mobilizon.GraphQL.Resolvers.Group,
        Mobilizon.GraphQL.Resolvers.Member,
        Mobilizon.GraphQL.Resolvers.Person,
        Mobilizon.GraphQL.Resolvers.Media,
        Mobilizon.GraphQL.Resolvers.Report,
        Mobilizon.GraphQL.Resolvers.Search,
        Mobilizon.GraphQL.Resolvers.Tag,
        Mobilizon.GraphQL.Resolvers.User,
        Mobilizon.GraphQL.Schema,
        Mobilizon.GraphQL.Schema.ActorInterface,
        Mobilizon.GraphQL.Schema.Actors.ApplicationType,
        Mobilizon.GraphQL.Schema.Actors.FollowerType,
        Mobilizon.GraphQL.Schema.Actors.GroupType,
        Mobilizon.GraphQL.Schema.Actors.MemberType,
        Mobilizon.GraphQL.Schema.Actors.PersonType,
        Mobilizon.GraphQL.Schema.AddressType,
        Mobilizon.GraphQL.Schema.AdminType,
        Mobilizon.GraphQL.Schema.Discussions.CommentType,
        Mobilizon.GraphQL.Schema.ConfigType,
        Mobilizon.GraphQL.Schema.EventType,
        Mobilizon.GraphQL.Schema.Events.FeedTokenType,
        Mobilizon.GraphQL.Schema.Events.ParticipantType,
        Mobilizon.GraphQL.Schema.MediaType,
        Mobilizon.GraphQL.Schema.ReportType,
        Mobilizon.GraphQL.Schema.SearchType,
        Mobilizon.GraphQL.Schema.SortType,
        Mobilizon.GraphQL.Schema.TagType,
        Mobilizon.GraphQL.Schema.UserType,
        Mobilizon.GraphQL.Schema.Utils,
        Mobilizon.GraphQL.Schema.Custom.Point,
        Mobilizon.GraphQL.Schema.Custom.UUID
      ],
      ActivityPub: [
        Mobilizon.Federation.ActivityPub,
        Mobilizon.Federation.ActivityPub.Audience,
        Mobilizon.Federation.ActivityPub.Federator,
        Mobilizon.Federation.ActivityPub.Relay,
        Mobilizon.Federation.ActivityPub.Transmogrifier,
        Mobilizon.Federation.ActivityPub.Visibility,
        Mobilizon.Federation.ActivityPub.Utils,
        Mobilizon.Federation.ActivityStream.Convertible,
        Mobilizon.Federation.ActivityStream.Converter,
        Mobilizon.Federation.ActivityStream.Converter.Actor,
        Mobilizon.Federation.ActivityStream.Converter.Address,
        Mobilizon.Federation.ActivityStream.Converter.Comment,
        Mobilizon.Federation.ActivityStream.Converter.Event,
        Mobilizon.Federation.ActivityStream.Converter.Flag,
        Mobilizon.Federation.ActivityStream.Converter.Follower,
        Mobilizon.Federation.ActivityStream.Converter.Participant,
        Mobilizon.Federation.ActivityStream.Converter.Media,
        Mobilizon.Federation.ActivityStream.Converter.Tombstone,
        Mobilizon.Federation.ActivityStream.Converter.Utils,
        Mobilizon.Federation.HTTPSignatures.Signature,
        Mobilizon.Federation.WebFinger,
        Mobilizon.Federation.WebFinger.XmlBuilder,
        Mobilizon.Web.Plugs.Federating,
        Mobilizon.Web.Plugs.HTTPSignatures,
        Mobilizon.Web.Plugs.MappedSignatureToIdentity,
        Mobilizon.Web.ActivityPubController,
        Mobilizon.Web.NodeInfoController,
        Mobilizon.Web.WebFingerController,
        Mobilizon.Web.ActivityPub.ActorView,
        Mobilizon.Web.ActivityPub.ObjectView
      ],
      Services: [
        Mobilizon.Service.Export.Feed,
        Mobilizon.Service.Export.ICalendar,
        Mobilizon.Service.Formatter,
        Mobilizon.Service.Formatter.HTML,
        Mobilizon.Service.Formatter.DefaultScrubbler,
        Mobilizon.Service.Metadata,
        Mobilizon.Service.Metadata.Actor,
        Mobilizon.Service.Metadata.Comment,
        Mobilizon.Service.Metadata.Event,
        Mobilizon.Service.Metadata.Instance,
        Mobilizon.Service.Metadata.Utils,
        Mobilizon.Service.Statistics,
        Mobilizon.Service.Workers.Background,
        Mobilizon.Service.Workers.BuildSearch,
        Mobilizon.Service.Workers.Helper
      ],
      Tools: [
        Mobilizon.Application,
        Mobilizon.Config,
        Mobilizon.Crypto,
        Mobilizon.Factory,
        Mobilizon.Storage.Ecto,
        Mobilizon.Storage.Page,
        Mobilizon.Storage.Repo
      ]
    ]
  end
end
