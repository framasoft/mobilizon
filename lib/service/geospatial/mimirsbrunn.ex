defmodule Mobilizon.Service.Geospatial.Mimirsbrunn do
  @moduledoc """
  [Mimirsbrunn](https://github.com/CanalTP/mimirsbrunn) backend.

  ## Issues
    * Has trouble finding POIs.
    * Doesn't support zoom level for reverse geocoding
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.GeospatialClient
  import Mobilizon.Service.Geospatial.Provider, only: [endpoint: 1]
  require Logger

  @behaviour Provider

  @impl Provider
  @doc """
  Mimirsbrunn implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(number(), number(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    :geocode
    |> build_url(%{lon: lon, lat: lat}, options)
    |> fetch_features
  end

  @impl Provider
  @doc """
  Mimirsbrunn implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
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

    case method do
      :search ->
        "#{endpoint}/autocomplete?q=#{URI.encode(args.q)}&lang=#{lang}&limit=#{limit}"
        |> add_parameter(options, :coords)
        |> add_parameter(options, :type)

      :geocode ->
        "#{endpoint}/reverse?lon=#{args.lon}&lat=#{args.lat}"
    end
  end

  @spec fetch_features(String.t()) :: list(Address.t())
  defp fetch_features(url) do
    Logger.debug("Asking addok with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"features" => features} <- body do
      process_data(features)
    else
      _ ->
        Logger.error("Asking addok with #{url}")
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

  defp process_address(%{"type" => "poi", "address" => address} = geocoding) do
    address = process_address(address)

    %Address{
      address
      | type: get_type(geocoding),
        origin_id: Map.get(geocoding, "id"),
        description: Map.get(geocoding, "name")
    }
  end

  defp process_address(geocoding) do
    %Address{
      country: get_administrative_region(geocoding, "country"),
      locality: Map.get(geocoding, "city"),
      region: get_administrative_region(geocoding, "region"),
      description: Map.get(geocoding, "name"),
      postal_code: get_postal_code(geocoding),
      street: street_address(geocoding),
      origin_id: "mimirsbrunn:" <> Map.get(geocoding, "id"),
      type: get_type(geocoding)
    }
  end

  defp street_address(properties) do
    if Map.has_key?(properties, "housenumber") do
      Map.get(properties, "housenumber") <> " " <> Map.get(properties, "street")
    else
      Map.get(properties, "street")
    end
  end

  defp get_type(%{"type" => type}) when type in ["house", "street", "zone", "address"], do: type

  defp get_type(%{"type" => "poi", "poi_types" => types})
       when is_list(types) and length(types) > 0,
       do: hd(types)["id"]

  defp get_type(_), do: nil

  defp get_administrative_region(
         %{"administrative_regions" => administrative_regions},
         administrative_level
       ) do
    Enum.find_value(
      administrative_regions,
      &process_administrative_region(&1, administrative_level)
    )
  end

  defp get_administrative_region(_, _), do: nil

  defp process_administrative_region(%{"zone_type" => "country", "name" => name}, "country"),
    do: name

  defp process_administrative_region(%{"zone_type" => "state", "name" => name}, "region"),
    do: name

  defp process_administrative_region(_, _), do: nil

  defp get_postal_code(%{"postcode" => nil}), do: nil
  defp get_postal_code(%{"postcode" => postcode}), do: postcode |> String.split(";") |> hd()

  @spec add_parameter(String.t(), Keyword.t(), atom()) :: String.t()
  defp add_parameter(url, options, key) do
    value = Keyword.get(options, key)

    if is_nil(value), do: url, else: do_add_parameter(url, key, value)
  end

  @spec do_add_parameter(String.t(), atom(), any()) :: String.t()
  defp do_add_parameter(url, :coords, coords),
    do: "#{url}&lat=#{coords.lat}&lon=#{coords.lon}"

  defp do_add_parameter(url, :type, :administrative),
    do: "#{url}&type=zone"

  defp do_add_parameter(url, :type, _type), do: url
end
