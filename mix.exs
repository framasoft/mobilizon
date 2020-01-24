defmodule Mobilizon.Mixfile do
  use Mix.Project

  @version "1.0.0-beta.2"

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
        Mobilizon.Admin,
        Mobilizon.Admin.ActionLog,
        Mobilizon.Events,
        Mobilizon.Events.Event,
        Mobilizon.Events.Comment,
        Mobilizon.Events.FeedToken,
        Mobilizon.Events.Participant,
        Mobilizon.Events.Session,
        Mobilizon.Events.Tag,
        Mobilizon.Events.TagRelations,
        Mobilizon.Events.Track,
        Mobilizon.Events.EventCategory,
        Mobilizon.Events.CommentVisibility,
        Mobilizon.Events.EventStatus,
        Mobilizon.Events.EventVisibility,
        Mobilizon.Events.JoinOptions,
        Mobilizon.Events.ParticipantRole,
        Mobilizon.Events.Tag.TitleSlug,
        Mobilizon.Events.Tag.TitleSlug.Type,
        Mobilizon.Events.TagRelation,
        Mobilizon.Media,
        Mobilizon.Media.File,
        Mobilizon.Media.Picture,
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
        MobilizonWeb.API.Comments,
        MobilizonWeb.API.Events,
        MobilizonWeb.API.Follows,
        MobilizonWeb.API.Groups,
        MobilizonWeb.API.Participations,
        MobilizonWeb.API.Reports,
        MobilizonWeb.API.Search,
        MobilizonWeb.API.Utils
      ],
      Web: [
        MobilizonWeb,
        MobilizonWeb.Endpoint,
        MobilizonWeb.Router,
        MobilizonWeb.Router.Helpers,
        MobilizonWeb.Plugs.UploadedMedia,
        MobilizonWeb.FallbackController,
        MobilizonWeb.FeedController,
        MobilizonWeb.MediaProxyController,
        MobilizonWeb.PageController,
        MobilizonWeb.ChangesetView,
        MobilizonWeb.JsonLD.ObjectView,
        MobilizonWeb.EmailView,
        MobilizonWeb.ErrorHelpers,
        MobilizonWeb.ErrorView,
        MobilizonWeb.LayoutView,
        MobilizonWeb.PageView,
        MobilizonWeb.Auth.Context,
        MobilizonWeb.Auth.ErrorHandler,
        MobilizonWeb.Auth.Guardian,
        MobilizonWeb.Auth.Pipeline,
        MobilizonWeb.Cache,
        MobilizonWeb.Cache.ActivityPub,
        MobilizonWeb.Email,
        MobilizonWeb.Email.Admin,
        MobilizonWeb.Email.Checker,
        MobilizonWeb.Email.Event,
        MobilizonWeb.Email.Mailer,
        MobilizonWeb.Email.Participation,
        MobilizonWeb.Email.User,
        MobilizonWeb.Upload,
        MobilizonWeb.Upload.Filter,
        MobilizonWeb.Upload.Filter.AnonymizeFilename,
        MobilizonWeb.Upload.Filter.Dedupe,
        MobilizonWeb.Upload.Filter.Mogrify,
        MobilizonWeb.Upload.Filter.Optimize,
        MobilizonWeb.Upload.MIME,
        MobilizonWeb.Upload.Uploader,
        MobilizonWeb.Upload.Uploader.Local,
        MobilizonWeb.MediaProxy,
        MobilizonWeb.ReverseProxy
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
        MobilizonWeb.Gettext
      ],
      GraphQL: [
        MobilizonWeb.GraphQLSocket,
        MobilizonWeb.Resolvers.Address,
        MobilizonWeb.Resolvers.Admin,
        MobilizonWeb.Resolvers.Comment,
        MobilizonWeb.Resolvers.Config,
        MobilizonWeb.Resolvers.Event,
        MobilizonWeb.Resolvers.FeedToken,
        MobilizonWeb.Resolvers.Group,
        MobilizonWeb.Resolvers.Member,
        MobilizonWeb.Resolvers.Person,
        MobilizonWeb.Resolvers.Picture,
        MobilizonWeb.Resolvers.Report,
        MobilizonWeb.Resolvers.Search,
        MobilizonWeb.Resolvers.Tag,
        MobilizonWeb.Resolvers.User,
        MobilizonWeb.Schema,
        MobilizonWeb.Schema.ActorInterface,
        MobilizonWeb.Schema.Actors.ApplicationType,
        MobilizonWeb.Schema.Actors.FollowerType,
        MobilizonWeb.Schema.Actors.GroupType,
        MobilizonWeb.Schema.Actors.MemberType,
        MobilizonWeb.Schema.Actors.PersonType,
        MobilizonWeb.Schema.AddressType,
        MobilizonWeb.Schema.AdminType,
        MobilizonWeb.Schema.CommentType,
        MobilizonWeb.Schema.ConfigType,
        MobilizonWeb.Schema.EventType,
        MobilizonWeb.Schema.Events.FeedTokenType,
        MobilizonWeb.Schema.Events.ParticipantType,
        MobilizonWeb.Schema.PictureType,
        MobilizonWeb.Schema.ReportType,
        MobilizonWeb.Schema.SearchType,
        MobilizonWeb.Schema.SortType,
        MobilizonWeb.Schema.TagType,
        MobilizonWeb.Schema.UserType,
        MobilizonWeb.Schema.Utils,
        MobilizonWeb.Schema.Custom.Point,
        MobilizonWeb.Schema.Custom.UUID
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
        Mobilizon.Federation.ActivityStream.Converter.Picture,
        Mobilizon.Federation.ActivityStream.Converter.Tombstone,
        Mobilizon.Federation.ActivityStream.Converter.Utils,
        Mobilizon.Federation.HTTPSignatures.Signature,
        Mobilizon.Federation.WebFinger,
        Mobilizon.Federation.WebFinger.XmlBuilder,
        MobilizonWeb.Plugs.Federating,
        MobilizonWeb.Plugs.HTTPSignatures,
        MobilizonWeb.Plugs.MappedSignatureToIdentity,
        MobilizonWeb.ActivityPubController,
        MobilizonWeb.NodeInfoController,
        MobilizonWeb.WebFingerController,
        MobilizonWeb.ActivityPub.ActorView,
        MobilizonWeb.ActivityPub.ObjectView
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
