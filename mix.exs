defmodule Mobilizon.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mobilizon,
      version: "0.0.1",
      elixir: "~> 1.4",
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
      source_url: "https://framagit.org/tcit/mobilizon",
      homepage_url: "https://framagit.org/tcit/mobilizon",
      docs: [main: "Mobilizon"]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Mobilizon.Application, []},
      extra_applications: [:logger, :runtime_tools, :guardian, :bamboo, :geolix]
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
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:guardian, "~> 1.0"},
      {:guardian_db, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.2"},
      {:cors_plug, "~> 1.2"},
      {:ecto_autoslug_field, "~> 0.3"},
      {:rsa_ex, "~> 0.1"},
      {:geo, "~> 3.0"},
      {:geo_postgis, "~> 2.0"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
      {:icalendar, "~> 0.6"},
      {:exgravatar, "~> 2.0.1"},
      {:httpoison, "~> 1.0"},
      {:json_ld, "~> 0.2"},
      {:jason, "~> 1.0"},
      {:ex_crypto, "~> 0.9.0"},
      {:http_sign, "~> 0.1.1"},
      {:ecto_enum, "~> 1.0"},
      {:ex_ical, "~> 0.2"},
      {:bamboo, "~> 1.0"},
      {:bamboo_smtp, "~> 1.5.0"},
      {:geolix, "~> 0.16"},
      {:absinthe, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:absinthe_plug, "~> 1.4.0"},
      {:poison, "~> 3.1"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:dataloader, "~> 1.0"},
      {:arc, "~> 0.11.0"},
      {:arc_ecto, "~> 0.11.0"},
      {:email_checker, "~> 0.1.2"},
      {:plug_cowboy, "~> 1.0"},
      # Dev and test dependencies
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:exvcr, "~> 0.10", only: :test}
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
