defmodule Eventos.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eventos,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      name: "Eventos",
      source_url: "https://framagit.org/tcit/eventos",
      homepage_url: "https://framagit.org/tcit/eventos",
      docs: [main: "Eventos"]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Eventos.Application, []},
      extra_applications: [:logger, :runtime_tools, :guardian]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

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
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:guardian, "~> 1.0"},
      {:guardian_db, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.2"},
      {:cors_plug, "~> 1.2"},
      {:ecto_autoslug_field, "~> 0.3"},
      {:rsa_ex, "~> 0.1"},
      {:geo, "~> 2.0"},
      {:geo_postgis, "~> 1.0"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
      {:ex_machina, "~> 2.1", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:dogma, "~> 0.1", only: [:dev, :test]},
      {:icalendar, "~> 0.6"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
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
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
