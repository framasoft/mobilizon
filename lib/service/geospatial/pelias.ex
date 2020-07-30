defmodule Mobilizon.Service.Geospatial.Pelias do
  @moduledoc """
  [Pelias](https://pelias.io) backend.

  Doesn't provide type of POI.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.BaseClient

  require Logger

  @behaviour Provider

  @endpoint Application.get_env(:mobilizon, __MODULE__) |> get_in([:endpoint])

  @impl Provider
  @doc """
  Pelias implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(number(), number(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)
    Logger.debug("Asking Pelias for reverse geocoding with #{url}")

    with {:ok, %{status: 200, body: body}} <- BaseClient.get(url),
         {:ok, %{"features" => features}} <- Jason.decode(body) do
      process_data(features)
    else
      _ -> []
    end
  end

  @impl Provider
  @doc """
  Pelias implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    url = build_url(:search, %{q: q}, options)
    Logger.debug("Asking Pelias for addresses with #{url}")

    with {:ok, %{status: 200, body: body}} <- BaseClient.get(url),
         {:ok, %{"features" => features}} <- Jason.decode(body) do
      process_data(features)
    else
      _ -> []
    end
  end

  @spec build_url(atom(), map(), list()) :: String.t()
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    coords = Keyword.get(options, :coords, nil)
    endpoint = Keyword.get(options, :endpoint, @endpoint)
    country_code = Keyword.get(options, :country_code)

    url =
      case method do
        :search ->
          url =
            "#{endpoint}/v1/autocomplete?text=#{URI.encode(args.q)}&lang=#{lang}&size=#{limit}"

          if is_nil(coords),
            do: url,
            else: url <> "&focus.point.lat=#{coords.lat}&focus.point.lon=#{coords.lon}"

        :geocode ->
          "#{endpoint}/v1/reverse?point.lon=#{args.lon}&point.lat=#{args.lat}"
      end

    if is_nil(country_code), do: url, else: "#{url}&boundary.country=#{country_code}"
  end

  defp process_data(features) do
    features
    |> Enum.map(fn %{
                     "geometry" => %{"coordinates" => coordinates},
                     "properties" => properties
                   } ->
      address = process_address(properties)
      %Address{address | geom: Provider.coordinates(coordinates)}
    end)
  end

  defp process_address(properties) do
    %Address{
      country: Map.get(properties, "country"),
      locality: Map.get(properties, "locality"),
      region: Map.get(properties, "region"),
      description: Map.get(properties, "name"),
      postal_code: Map.get(properties, "postalcode"),
      street: street_address(properties),
      origin_id: "pelias:#{Map.get(properties, "id")}",
      type: get_type(properties)
    }
  end

  defp street_address(properties) do
    if Map.has_key?(properties, "housenumber") do
      "#{Map.get(properties, "housenumber")} #{Map.get(properties, "street")}"
    else
      Map.get(properties, "street")
    end
  end

  @administrative_layers [
    "neighbourhood",
    "borough",
    "localadmin",
    "locality",
    "county",
    "macrocounty",
    "region",
    "macroregion",
    "dependency"
  ]

  defp get_type(%{"layer" => layer}) when layer in @administrative_layers, do: "administrative"
  defp get_type(%{"layer" => "address"}), do: "house"
  defp get_type(%{"layer" => "street"}), do: "street"
  defp get_type(%{"layer" => "venue"}), do: "venue"
  defp get_type(%{"layer" => _}), do: nil
end
