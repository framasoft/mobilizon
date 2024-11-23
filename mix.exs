defmodule Mobilizon.Mixfile do
  use Mix.Project

  @version "5.1.0"

  def project do
    [
      app: :mobilizon,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      xref: [exclude: [:eldap]],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "Mobilizon",
      source_url: "https://framagit.org/framasoft/mobilizon",
      homepage_url: "https://joinmobilizon.org",
      docs: docs(),
      releases: [
        mobilizon: [
          include_executables_for: [:unix],
          applications: [eldap: :transient],
          config_providers: [{Mobilizon.ConfigProvider, "/etc/mobilizon/config.exs"}],
          steps: [:assemble, &copy_files/1, &copy_config/1]
        ]
      ],
      unused: [
        ignore: [
          Mobilizon.Storage.PostgresTypes,
          Mobilizon.Factory,
          Mobilizon.Web.Router.Helpers,
          Mobilizon.Web.Email.Mailer,
          Mobilizon.Web.Auth.Guardian.Plug,
          Mobilizon.Web.Gettext,
          Mobilizon.Web.Endpoint,
          Mobilizon.Web.Auth.Guardian,
          Mobilizon.Web,
          Mobilizon.GraphQL.Schema.Compiled,
          Mobilizon.GraphQL.Schema,
          Mobilizon.Web.Router,
          Mobilizon.Users.Setting.Location,
          {:_, :start_link, 1},
          {:_, :child_spec, 1},
          {:_, :__impl__, 1},
          {:_, :__schema__, :_},
          {:_, :__struct__, 0..1},
          {:_, :__changeset__, 0},
          {:_, :create_type, 0},
          {:_, :drop_type, 0},
          {:_, :schema, 0},
          {:_, :schemaless_type, 0},
          {:_, :valid_value?, 0..1},
          {:_, :__enum_map__, 0},
          {:_, :__absinthe_blueprint__, :_},
          {:_, :__absinthe_function__, :_},
          {~r/^Mobilizon.Web.*Controller/, :_, 2},
          {~r/^Mobilizon.Web.*View/, :_, :_},
          {~r/^Mobilizon.Web.Email.*/, :render, 3},
          {~r/^Mobilizon.Service.HTTP.*Client/, :_, :_},
          {~r/^Mobilizon.Cldr.*/, :_, :_},
          {Mobilizon.Web.GraphQLSocket, :__channel__, 1}
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
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:test) do
    extra_applications(:prod) ++ [:inets, :ssl]
  end

  defp extra_applications(_env) do
    [:tls_certificate_check, :logger, :runtime_tools, :guardian, :geolix, :crypto, :cachex]
  end

  def copy_files(%{path: target_path} = release) do
    File.cp_r!("./rel/overlays", target_path)
    release
  end

  def copy_config(%{path: target_path} = release) do
    support_path = Path.join([target_path, "support"])
    File.mkdir!(support_path)

    File.cp_r!(
      "./support",
      support_path
    )

    release
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
        case String.split(strategy_entry, ":") do
          [_strategy, dependency] ->
            dependency

          [strategy] ->
            "ueberauth_#{strategy}"
        end
      end)

    for s <- oauth_strategy_packages, do: {String.to_atom(s), ">= 0.0.0"}
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.17.1"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_view, "~> 2.0"},
      {:gettext, "~> 0.24"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 3.0.0"},
      {:guardian_phoenix, "~> 2.0"},
      {:argon2_elixir, "~> 4.0"},
      {:cors_plug, "~> 3.0"},
      {:ecto_autoslug_field, "~> 3.0"},
      {:geo, "~> 3.0"},
      {:geo_postgis, "~> 3.1"},
      {:timex, "~> 3.0"},
      {:icalendar, github: "tcitworld/icalendar"},
      {:exgravatar, "~> 2.0.1"},
      # {:json_ld, "~> 0.3"},
      {:jason, "~> 1.2"},
      {:ecto_enum, "~> 1.4"},
      {:ex_ical, "~> 0.2"},
      {:swoosh, "~> 1.7"},
      {:gen_smtp, "~> 1.1"},
      {:phoenix_swoosh, "~> 1.0"},
      {:geolix, "~> 2.0"},
      {:geolix_adapter_mmdb2, "~> 0.6.0"},
      {:absinthe, "~> 1.6"},
      {:absinthe_phoenix, "~> 2.0.1"},
      {:absinthe_plug, "~> 1.5.0"},
      {:dataloader, "~> 2.0"},
      {:atomex, "~> 0.4"},
      {:cachex, "~> 3.1"},
      {:geohax, "~> 1.0.0"},
      {:mogrify, "~> 0.9"},
      {:linkify, "~> 0.3"},
      {:http_signatures, "~> 0.1.0"},
      {:ex_cldr, "~> 2.33"},
      {:ex_cldr_dates_times, "~> 2.2"},
      {:ex_cldr_plugs, "~> 1.0"},
      {:ex_optimizer, "~> 0.1"},
      {:progress_bar, "~> 3.0"},
      {:oban, "~> 2.2"},
      {:floki, "~> 0.31"},
      {:ip_reserved, "~> 0.1.0"},
      {:fast_sanitize, "~> 0.1"},
      {:ueberauth, "0.10.8", override: true},
      {:ueberauth_twitter, "~> 0.4"},
      {:ueberauth_discord, "~> 0.7"},
      {:ueberauth_github, "~> 0.8.1"},
      {:ueberauth_facebook, "~> 0.9"},
      {:ueberauth_google, "~> 0.12.1"},
      {:ueberauth_keycloak_strategy, "~> 0.4.0"},
      {:ueberauth_gitlab_strategy, "~> 0.4.0"},
      {:ueberauth_cas, "~> 2.0"},
      {:ecto_shortuuid, "~> 0.1"},
      {:tesla, "~> 1.8.0"},
      {:sitemapper, "~> 0.6"},
      {:xml_builder, "~> 2.2"},
      {:remote_ip, "~> 1.1"},
      {:ex_cldr_languages, "~> 0.3.0"},
      {:slugger, "~> 0.3"},
      {:sentry, "~> 8.1"},
      {:html_entities, "~> 0.5"},
      {:sweet_xml, "~> 0.7"},
      {:web_push_encryption, github: "danhper/elixir-web-push-encryption"},
      {:eblurhash, "~> 1.2.0"},
      {:struct_access, "~> 1.1.2"},
      {:paasaa, "~> 0.6.0"},
      {:nimble_csv, "~> 1.1"},
      {:export, "~> 0.1.0"},
      {:erlport, "~> 0.11.0"},
      {:tz_world, "~> 1.3.0"},
      {:tzdata, "~> 1.1"},
      {:codepagex, "~> 0.1.6"},
      {:vite_phx, "~> 0.2"},
      {:unplug, "~> 1.0.0"},
      {:replug, "~> 0.1.0"},
      {:exkismet, github: "tcitworld/exkismet"},
      {:rajska, github: "tcitworld/rajska", branch: "mobilizon"},
      {:hammer, "~> 6.1"},
      {:tls_certificate_check, "~> 1.20"},
      {:bandit, "~> 1.0"},
      # Dev and test dependencies
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :e2e]},
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      {:excoveralls, "~> 0.18.0", only: :test},
      {:ex_doc, "~> 0.25", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.4", only: :test},
      {:elixir_feed_parser, "~> 2.1.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:sobelow, "~> 0.8", only: [:dev, :test]},
      {:doctor, "~> 0.21", only: :dev},
      {:haversine, "~> 0.1.0"},
      {:ecto_dev_logger, "~> 0.7"},
      {:credo_code_climate, "~> 0.1.0", only: [:dev, :test]}
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
      prepare_test: [
        "ecto.create",
        "ecto.migrate",
        "tz_world.update"
      ],
      test: [
        &run_test/1
      ],
      "phx.deps_migrate_serve": [
        "deps.get",
        "ecto.create --quiet",
        "ecto.migrate",
        "cmd npm ci",
        "phx.server"
      ]
    ]
  end

  defp run_test(args) do
    File.mkdir("test/uploads")
    Mix.Task.run("test", args)
    File.rm_rf!("test/uploads")
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      groups_for_modules: groups_for_modules(),
      nest_modules_by_prefix: [
        Mobilizon,
        Mobilizon.Activities,
        Mobilizon.Actors,
        Mobilizon.Admin,
        Mobilizon.Discussions,
        Mobilizon.Events,
        Mobilizon.GraphQL,
        Mobilizon.Medias,
        Mobilizon.Posts,
        Mobilizon.Reports,
        Mobilizon.Resources,
        Mobilizon.Todos,
        Mobilizon.Users,
        Mobilizon.Federation,
        Mobilizon.Federation.ActivityPub,
        Mobilizon.Federation.ActivityPub.Actions,
        Mobilizon.Federation.ActivityPub.Types,
        Mobilizon.Federation.ActivityStream,
        Mobilizon.Federation.ActivityStream.Converter,
        Mobilizon.GraphQL.Resolvers,
        Mobilizon.GraphQL.Schema,
        Mobilizon.Service,
        Mobilizon.Service.Activity,
        Mobilizon.Service.Export,
        Mobilizon.Service.Geospatial,
        Mobilizon.Service.Metadata,
        Mobilizon.Service.Workers,
        Mobilizon.Web,
        Mobilizon.Web.Email,
        Mobilizon.Web.Plugs,
        Mobilizon.Web.Upload
      ]
    ]
  end

  defp groups_for_modules do
    [
      Models: [
        ~r/Mobilizon.Actors~r/,
        ~r/Mobilizon.Addresses/,
        ~r/Mobilizon.Admin/,
        ~r/Mobilizon.Events/,
        ~r/Mobilizon.Instances/,
        ~r/Mobilizon.Medias/,
        ~r/Mobilizon.Mention/,
        ~r/Mobilizon.Reports/,
        ~r/Mobilizon.Share/,
        ~r/Mobilizon.Tombstone/,
        ~r/Mobilizon.Users/
      ],
      "GraphQL APIs": [
        ~r/Mobilizon.GraphQL.API/
      ],
      Emails: [
        ~r/Mobilizon.Web.Email/
      ],
      Web: [
        ~r/Mobilizon.Web/
      ],
      Geospatial: [
        ~r/Mobilizon.Service.Geospatial/
      ],
      Localization: [
        ~r/Mobilizon.Cldr/,
        ~r/Mobilizon.Web.Gettext/
      ],
      GraphQL: [
        ~r/Mobilizon.Web.GraphQLSocket/,
        ~r/Mobilizon.GraphQL/
      ],
      ActivityPub: [
        ~r/Mobilizon.Federation.ActivityPub/,
        ~r/Mobilizon.Federation.ActivityStream/,
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
        ~r/Mobilizon.Service/
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
