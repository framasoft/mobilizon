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

  alias Mobilizon.Config
  alias Mobilizon.Service.Export.{Feed, ICalendar}

  @name Mix.Project.config()[:name]
  @version Mix.Project.config()[:version]

  @spec named_version :: String.t()
  def named_version, do: "#{@name} #{@version}"

  @spec user_agent :: String.t()
  def user_agent do
    info = "#{MobilizonWeb.Endpoint.url()} <#{Config.get([:instance, :email], "")}>"

    "#{named_version()}; #{info}"
  end

  @spec start(:normal | {:takeover, node} | {:failover, node}, term) ::
          {:ok, pid} | {:ok, pid, term} | {:error, term}
  def start(_type, _args) do
    children = [
      # supervisors
      Mobilizon.Storage.Repo,
      MobilizonWeb.Endpoint,
      {Absinthe.Subscription, [MobilizonWeb.Endpoint]},
      {Oban, Application.get_env(:mobilizon, Oban)},
      # workers
      Guardian.DB.Token.SweeperServer,
      Mobilizon.Service.Federator,
      cachex_spec(:feed, 2500, 60, 60, &Feed.create_cache/1),
      cachex_spec(:ics, 2500, 60, 60, &ICalendar.create_cache/1),
      cachex_spec(:statistics, 10, 60, 60),
      cachex_spec(:activity_pub, 2500, 3, 15),
      internal_actor()
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mobilizon.Supervisor)
  end

  @spec config_change(keyword, keyword, [atom]) :: :ok
  def config_change(changed, _new, removed) do
    MobilizonWeb.Endpoint.config_change(changed, removed)

    :ok
  end

  @spec cachex_spec(atom, integer, integer, integer, function | nil) :: Supervisor.child_spec()
  defp cachex_spec(name, limit, default, interval, fallback \\ nil) do
    %{
      id: :"cache_#{name}",
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

  defp internal_actor() do
    %{
      id: :internal_actor_init,
      start: {Task, :start_link, [&Mobilizon.Service.ActivityPub.Relay.init/0]},
      restart: :temporary
    }
  end
end
