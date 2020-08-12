defmodule Mobilizon.Service.SiteMap do
  @moduledoc """
  Generates a sitemap
  """

  alias Mobilizon.{Actors, Events, Posts}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @default_static_frequency :monthly

  def generate_sitemap do
    static_routes = [
      {Routes.page_url(Endpoint, :index, []), :daily},
      "#{Endpoint.url()}/about/instance",
      "#{Endpoint.url()}/about/mobilizon",
      "#{Endpoint.url()}/terms",
      "#{Endpoint.url()}/privacy",
      "#{Endpoint.url()}/rules",
      "#{Endpoint.url()}/glossary"
    ]

    config = [
      store: Sitemapper.FileStore,
      store_config: [path: "priv/static"],
      sitemap_url: Endpoint.url(),
      gzip: false
    ]

    Repo.transaction(fn ->
      Events.stream_events_for_sitemap()
      |> Stream.concat(Actors.list_groups_for_stream())
      |> Stream.concat(Posts.list_posts_for_stream())
      |> Stream.concat(
        Enum.map(static_routes, fn route ->
          {url, frequency} =
            case route do
              {url, frequency} -> {url, frequency}
              url when is_binary(url) -> {url, @default_static_frequency}
            end

          %{url: url, updated_at: nil, frequence: frequency}
        end)
      )
      |> Stream.map(fn %{url: url, updated_at: updated_at} = args ->
        frequence = Map.get(args, :frequence, :weekly)

        %Sitemapper.URL{
          loc: url,
          changefreq: frequence,
          lastmod: check_date_time(updated_at)
        }
      end)
      |> Sitemapper.generate(config)
      |> Sitemapper.persist(config)
      |> Sitemapper.ping(config)
      |> Stream.run()
    end)
  end

  # Sometimes we use naive datetimes
  defp check_date_time(%NaiveDateTime{} = datetime), do: DateTime.from_naive!(datetime, "Etc/UTC")
  defp check_date_time(%DateTime{} = datetime), do: datetime
  defp check_date_time(_), do: nil
end
