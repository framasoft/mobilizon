defmodule Mobilizon do
  @moduledoc """
  Mobilizon is a decentralized and federated Meetup-like using
  [ActivityPub](http://activitypub.rocks/).

  It consists of an API server build with [Elixir](http://elixir-lang.github.io/)
  and the [Phoenix Framework](https://hexdocs.pm/phoenix).

  Mobilizon relies on `Guardian` for auth and `Geo`/Postgis for geographical
  information.
  """

  use Application

  import Cachex.Spec

  alias Mobilizon.{Config, Storage, Web}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Service.{ErrorPage, ErrorReporting}
  alias Mobilizon.Service.Export.{Feed, ICalendar}

  @name Mix.Project.config()[:name]
  @version Mix.Project.config()[:version]
  @env Application.compile_env(:mobilizon, :env)

  @spec named_version :: String.t()
  def named_version, do: "#{@name} #{@version}"

  @spec user_agent :: String.t()
  def user_agent do
    info = "#{Web.Endpoint.url()} <#{Config.get([:instance, :email], "")}>"

    "#{named_version()}; #{info}"
  end

  @spec start(:normal | {:takeover, node} | {:failover, node}, term) ::
          {:ok, pid} | {:ok, pid, term} | {:error, term}
  def start(_type, _args) do
    children =
      [
        # supervisors
        Storage.Repo,
        {Phoenix.PubSub, name: Mobilizon.PubSub},
        Web.Endpoint,
        {Absinthe.Subscription, Web.Endpoint},
        {Oban, Application.get_env(:mobilizon, Oban)},
        # workers
        Guardian.DB.Sweeper,
        ActivityPub.Federator,
        TzWorld.Backend.DetsWithIndexCache,
        cachex_spec(:feed, 2500, 60, 60, &Feed.create_cache/1),
        cachex_spec(:ics, 2500, 60, 60, &ICalendar.create_cache/1),
        cachex_spec(
          :actor_key_rotation,
          2500,
          div(Application.get_env(:mobilizon, :activitypub)[:actor_key_rotation_delay], 60),
          60 * 30
        ),
        cachex_spec(:statistics, 10, 60, 60),
        cachex_spec(:config, 10, 60, 60),
        cachex_spec(:rich_media_cache, 10, 60, 60),
        cachex_spec(:activity_pub, 2500, 3, 15),
        cachex_spec(:default_actors, 2500, 3, 15),
        %{
          id: :cache_key_value,
          start: {Cachex, :start_link, [:key_value]}
        }
      ] ++
        task_children(@env)

    children =
      if Mobilizon.PythonPort.python_exists?() do
        children ++ [Mobilizon.PythonWorker]
      else
        children
      end

    ErrorReporting.configure()

    setup_ecto_dev_logger(@env)

    # Only attach the telemetry logger when we aren't in an IEx shell
    unless Code.ensure_loaded?(IEx) && IEx.started?() do
      Oban.Telemetry.attach_default_logger(:info)
      ErrorReporting.attach()
    end

    with :ok <- load_certificates() do
      Supervisor.start_link(children, strategy: :one_for_one, name: Mobilizon.Supervisor)
    end
  end

  @spec config_change(keyword, keyword, [atom]) :: :ok
  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)

    :ok
  end

  # sobelow_skip ["DOS.StringToAtom"]
  @spec cachex_spec(atom, integer, integer, integer, function | nil) :: Supervisor.child_spec()
  defp cachex_spec(name, limit, default, interval, fallback \\ nil) do
    %{
      id: String.to_atom("cache_#{to_string(name)}"),
      start:
        {Cachex, :start_link,
         [
           name,
           Keyword.merge(
             cachex_options(limit, default, interval),
             fallback_options(fallback)
           )
         ]}
    }
  end

  @spec cachex_options(integer, integer, integer) :: keyword
  defp cachex_options(limit, default, interval) do
    [
      limit: limit,
      expiration:
        expiration(
          default: :timer.minutes(default),
          interval: :timer.seconds(interval)
        )
    ]
  end

  @spec fallback_options(function | nil) :: keyword
  defp fallback_options(nil), do: []
  defp fallback_options(fallback), do: [fallback: fallback(default: fallback)]

  defp task_children(:test), do: []
  defp task_children(_), do: [relay_actor(), anonymous_actor(), render_error_page()]

  defp relay_actor do
    %{
      id: :relay_actor_init,
      start: {Task, :start_link, [&ActivityPub.Relay.init/0]},
      restart: :temporary
    }
  end

  defp anonymous_actor do
    %{
      id: :anonymous_actor_init,
      start: {Task, :start_link, [&Mobilizon.Config.anonymous_actor_id/0]},
      restart: :temporary
    }
  end

  defp render_error_page do
    %{
      id: :render_error_page_init,
      start: {Task, :start_link, [&ErrorPage.init/0]},
      restart: :temporary
    }
  end

  defp setup_ecto_dev_logger(:dev) do
    Ecto.DevLogger.install(Storage.Repo)
  end

  defp setup_ecto_dev_logger(_), do: nil

  defp load_certificates do
    custom_cert_path = System.get_env("MOBILIZON_CA_CERT_PATH")

    if is_binary(custom_cert_path) do
      with :ok <- :tls_certificate_check.override_trusted_authorities({:file, custom_cert_path}) do
        :public_key.cacerts_load(custom_cert_path)
      end
    else
      :ok
    end
  end
end
