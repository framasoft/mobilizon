defmodule Mobilizon.Service.Geospatial.Nominatim do
  @moduledoc """
  [Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) backend.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.GeospatialClient
  import Mobilizon.Service.Geospatial.Provider, only: [endpoint: 1]
  require Logger

  @behaviour Provider

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    :geocode
    |> build_url(%{lon: lon, lat: lat}, options)
    |> fetch_features
  end

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    :search
    |> build_url(%{q: q}, options)
    |> fetch_features
  end

  @spec build_url(atom(), map(), list()) :: String.t()
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    endpoint = Keyword.get(options, :endpoint, endpoint(__MODULE__))

    url =
      case method do
        :search ->
          "#{endpoint}/search?format=geocodejson&q=#{URI.encode(args.q)}&limit=#{limit}&accept-language=#{
            lang
          }&addressdetails=1&namedetails=1"

        :geocode ->
          "#{endpoint}/reverse?format=geocodejson&lat=#{args.lat}&lon=#{args.lon}&accept-language=#{
            lang
          }&addressdetails=1&namedetails=1"
          |> add_parameter(options, :zoom)
      end

    url
    |> add_parameter(options, :country_code)
    |> add_parameter(options, :api_key, api_key())
  end

  @spec fetch_features(String.t()) :: list(Address.t())
  defp fetch_features(url) do
    Logger.debug("Asking Nominatim with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"features" => features} <- body do
      features |> process_data |> Enum.filter(& &1)
    else
      _ ->
        Logger.error("Asking Nominatim with #{url}")
        []
    end
  end

  defp process_data(features) do
    features
    |> Enum.map(fn %{
                     "geometry" => %{"coordinates" => coordinates},
                     "properties" => %{"geocoding" => geocoding}
                   } ->
      address = process_address(geocoding)
      %Address{address | geom: Provider.coordinates(coordinates)}
    end)
  end

  defp process_address(geocoding) do
    %Address{
      country: Map.get(geocoding, "country"),
      locality:
        Map.get(geocoding, "city") || Map.get(geocoding, "town") || Map.get(geocoding, "county"),
      region: Map.get(geocoding, "state"),
      description: description(geocoding),
      postal_code: Map.get(geocoding, "postcode"),
      type: Map.get(geocoding, "type"),
      street: street_address(geocoding),
      origin_id: "nominatim:" <> to_string(Map.get(geocoding, "osm_id"))
    }
  end

  @spec street_address(map()) :: String.t()
  defp street_address(body) do
    road =
      cond do
        Map.has_key?(body, "road") ->
          Map.get(body, "road")

        Map.has_key?(body, "street") ->
          Map.get(body, "street")

        Map.has_key?(body, "pedestrian") ->
          Map.get(body, "pedestrian")

        true ->
          ""
      end

    Map.get(body, "housenumber", "") <> " " <> road
  end

  @address29_classes ["amenity", "shop", "tourism", "leisure"]
  @address29_categories ["office"]

  @spec description(map()) :: String.t()
  defp description(body) do
    description = Map.get(body, "name")
    address = Map.get(body, "address")

    description =
      if Map.has_key?(body, "namedetails"),
        do: body |> Map.get("namedetails") |> Map.get("name", description),
        else: description

    description = if is_nil(description), do: street_address(body), else: description

    if (Map.get(body, "category") in @address29_categories or
          Map.get(body, "class") in @address29_classes) and Map.has_key?(address, "address29") do
      Map.get(address, "address29")
    else
      description
    end
  end

  @spec add_parameter(String.t(), Keyword.t(), atom()) :: String.t()
  defp add_parameter(url, options, key, default \\ nil) do
    value = Keyword.get(options, key, default)

    if is_nil(value), do: url, else: do_add_parameter(url, key, value)
  end

  @spec do_add_parameter(String.t(), atom(), any()) :: String.t()
  defp do_add_parameter(url, :zoom, zoom),
    do: "#{url}&zoom=#{zoom}"

  @spec do_add_parameter(String.t(), atom(), any()) :: String.t()
  defp do_add_parameter(url, :country_code, country_code),
    do: "#{url}&countrycodes=#{country_code}"

  @spec do_add_parameter(String.t(), atom(), any()) :: String.t()
  defp do_add_parameter(url, :api_key, api_key),
    do: "#{url}&key=#{api_key}"

  defp api_key do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])
  end
end
