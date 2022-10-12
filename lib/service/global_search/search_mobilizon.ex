defmodule Mobilizon.Service.GlobalSearch.SearchMobilizon do
  @moduledoc """
  [Search Mobilizon](https://search.joinmobilizon.org) backend.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.{Categories, Tag}
  alias Mobilizon.Service.GlobalSearch.{EventResult, GroupResult, Provider}
  alias Mobilizon.Service.HTTP.GenericJSONClient
  alias Mobilizon.Storage.Page
  require Logger
  import Plug.Conn.Query, only: [encode: 1]

  @search_events_api "/api/v1/search/events"
  @search_groups_api "/api/v1/search/groups"

  @sort_by_options %{
    match_desc: "-match",
    start_time_desc: "-startTime",
    created_at_desc: "-createdAt",
    created_at_asc: "createdAt",
    participant_count_desc: "-participantCount",
    member_count_desc: "-memberCount"
  }

  @behaviour Provider

  @impl Provider
  @doc """
  Mobilizon Search implementation for `c:Mobilizon.Service.GlobalSearch.Provider.search_events/3`.
  """
  @spec search_events(keyword()) :: Page.t(EventResult.t())
  def search_events(options \\ []) do
    Logger.debug("Search events options, #{inspect(Keyword.keys(options))}")

    options =
      options
      |> Keyword.merge(
        search: options[:term],
        startDateMin: to_date(options[:begins_on]),
        startDateMax: to_date(options[:ends_on]),
        categoryOneOf: options[:category_one_of],
        languageOneOf: options[:language_one_of],
        statusOneOf:
          Enum.map(options[:status_one_of] || [], fn status ->
            status |> Atom.to_string() |> String.upcase()
          end),
        distance: if(options[:radius], do: "#{options[:radius]}_km", else: nil),
        count: options[:limit],
        start: (Keyword.get(options, :page, 1) - 1) * Keyword.get(options, :limit, 16),
        latlon: to_lat_lon(options[:location]),
        bbox: options[:bbox],
        sortBy: Map.get(@sort_by_options, options[:sort_by]),
        boostLanguages: options[:boost_languages]
      )
      |> Keyword.take([
        :search,
        :startDateMin,
        :startDateMax,
        :boostLanguages,
        :categoryOneOf,
        :languageOneOf,
        :latlon,
        :distance,
        :sort,
        :statusOneOf,
        :bbox,
        :start,
        :count,
        :sortBy
      ])
      |> Keyword.reject(fn {_key, val} -> is_nil(val) or val == "" end)

    events_url = "#{search_endpoint()}#{@search_events_api}?#{encode(options)}"
    Logger.debug("Calling global search engine url #{events_url}")

    client = GenericJSONClient.client()

    case GenericJSONClient.get(client, events_url) do
      {:ok, %{status: 200, body: body}} ->
        %Page{total: body["total"], elements: Enum.map(body["data"], &build_event/1)}

      _ ->
        nil
    end
  end

  @impl Provider
  @doc """
  Mobilizon Search implementation for `c:Mobilizon.Service.GlobalSearch.Provider.search_groups/3`.
  """
  @spec search_groups(keyword()) :: Page.t(GroupResult.t())
  def search_groups(options \\ []) do
    options =
      options
      |> Keyword.merge(
        search: options[:term],
        languageOneOf: options[:language_one_of],
        boostLanguages: options[:boost_languages],
        distance: if(options[:radius], do: "#{options[:radius]}_km", else: nil),
        count: options[:limit],
        start: (options[:page] - 1) * options[:limit],
        latlon: to_lat_lon(options[:location]),
        bbox: options[:bbox],
        sortBy: Map.get(@sort_by_options, options[:sort_by])
      )
      |> Keyword.take([
        :search,
        :languageOneOf,
        :boostLanguages,
        :latlon,
        :distance,
        :sort,
        :start,
        :count,
        :bbox,
        :sortBy
      ])
      |> Keyword.reject(fn {_key, val} -> is_nil(val) or val == "" end)

    groups_url = "#{search_endpoint()}#{@search_groups_api}?#{encode(options)}"
    Logger.debug("Calling global search engine url #{groups_url}")

    client = GenericJSONClient.client()

    case GenericJSONClient.get(client, groups_url) do
      {:ok, %{status: 200, body: body}} ->
        %Page{total: body["total"], elements: Enum.map(body["data"], &build_group/1)}

      _ ->
        nil
    end
  end

  @impl Provider
  @doc """
  Returns the CSP configuration for this search provider to work
  """
  def csp do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:csp_policy, [])
  end

  defp build_event(data) do
    picture =
      if data["banner"] do
        %{url: data["banner"], id: data["banner"]}
      else
        nil
      end

    organizer_actor_avatar =
      if data["creator"]["avatar"] do
        %{url: data["creator"]["avatar"], id: data["creator"]["avatar"]}
      else
        nil
      end

    address =
      if data["location"] do
        %Address{
          id: data["location"]["id"],
          country: data["location"]["address"]["addressCountry"],
          locality: data["location"]["address"]["addressLocality"],
          region: data["location"]["address"]["addressRegion"],
          postal_code: data["location"]["address"]["postalCode"],
          street: data["location"]["address"]["streetAddress"],
          url: data["location"]["id"],
          description: data["location"]["name"],
          geom: %Geo.Point{
            coordinates:
              {data["location"]["location"]["lon"], data["location"]["location"]["lat"]},
            srid: 4326
          }
        }
      else
        nil
      end

    %EventResult{
      id: data["id"],
      uuid: data["uuid"],
      title: data["name"],
      begins_on: parse_date(data["startTime"]),
      ends_on: parse_date(data["endTime"]),
      url: data["url"],
      picture: picture,
      category:
        data["category"]
        |> Categories.get_category()
        |> String.downcase()
        |> String.to_existing_atom(),
      organizer_actor: %Actor{
        id: data["creator"]["id"],
        name: data["creator"]["displayName"],
        preferred_username: data["creator"]["name"],
        avatar: organizer_actor_avatar
      },
      physical_address: address,
      participant_stats: %{participant: data["participantCount"]},
      tags:
        Enum.map(data["tags"], fn tag ->
          tag = String.trim_leading(tag, "#")
          %Tag{id: tag, slug: tag, title: tag}
        end)
    }
  end

  defp build_group(data) do
    avatar =
      if data["avatar"] do
        %{url: data["avatar"], id: data["avatar"]}
      else
        nil
      end

    address =
      if data["location"] do
        %Address{
          id: data["location"]["id"],
          country: data["location"]["address"]["addressCountry"],
          locality: data["location"]["address"]["addressLocality"],
          region: data["location"]["address"]["addressRegion"],
          postal_code: data["location"]["address"]["postalCode"],
          street: data["location"]["address"]["streetAddress"],
          url: data["location"]["id"],
          description: data["location"]["name"],
          geom: %Geo.Point{
            coordinates:
              {data["location"]["location"]["lon"], data["location"]["location"]["lat"]},
            srid: 4326
          }
        }
      else
        nil
      end

    %GroupResult{
      id: data["id"],
      name: data["displayName"],
      preferred_username: data["name"],
      domain: data["host"],
      avatar: avatar,
      summary: data["description"],
      url: data["url"],
      members_count: data["memberCount"],
      type: :Group,
      physical_address: address
    }
  end

  defp search_endpoint do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:endpoint]) ||
      "https://search.joinmobilizon.org"
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, date, _} -> date
      {:error, _} -> nil
    end
  end

  defp to_date(nil), do: nil
  defp to_date(date), do: DateTime.to_iso8601(date)

  defp to_lat_lon(nil), do: nil

  defp to_lat_lon(location) do
    {lon, lat} = Geohax.decode(location)
    "#{lat}:#{lon}"
  end
end
