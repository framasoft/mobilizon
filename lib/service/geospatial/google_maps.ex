defmodule Mobilizon.Service.Geospatial.GoogleMaps do
  @moduledoc """
  Google Maps [Geocoding service](https://developers.google.com/maps/documentation/geocoding/intro). Only works with addresses.

  Note: Endpoint is hardcoded to Google Maps API.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.GeospatialClient

  require Logger

  @behaviour Provider

  @api_key Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])

  @fetch_place_details (Application.get_env(:mobilizon, __MODULE__)
                        |> get_in([:fetch_place_details])) in [true, "true", "True"]

  @components [
    "street_number",
    "route",
    "locality",
    "administrative_area_level_1",
    "country",
    "postal_code"
  ]

  @api_key_missing_message "API Key required to use Google Maps"

  @impl Provider
  @doc """
  Google Maps implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)

    Logger.debug("Asking Google Maps for reverse geocode with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"results" => results, "status" => "OK"} <- body do
      Enum.map(results, fn entry -> process_data(entry, options) end)
    else
      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)
    end
  end

  @impl Provider
  @doc """
  Google Maps implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    url = build_url(:search, %{q: q}, options)

    Logger.debug("Asking Google Maps for addresses with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"results" => results, "status" => "OK"} <- body do
      results |> Enum.map(fn entry -> process_data(entry, options) end)
    else
      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)

      %{"results" => [], "status" => "ZERO_RESULTS"} ->
        []
    end
  end

  @spec build_url(atom(), map(), list()) :: String.t()
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    api_key = Keyword.get(options, :api_key, @api_key)
    if is_nil(api_key), do: raise(ArgumentError, message: @api_key_missing_message)

    url =
      "https://maps.googleapis.com/maps/api/geocode/json?limit=#{limit}&key=#{api_key}&language=#{
        lang
      }"

    uri =
      case method do
        :search ->
          url <> "&address=#{args.q}"

        :geocode ->
          zoom = Keyword.get(options, :zoom, 15)

          result_type = if zoom >= 15, do: "street_address", else: "locality"

          url <> "&latlng=#{args.lat},#{args.lon}&result_type=#{result_type}"

        :place_details ->
          "https://maps.googleapis.com/maps/api/place/details/json?key=#{api_key}&placeid=#{
            args.place_id
          }"
      end

    URI.encode(uri)
  end

  defp process_data(
         %{
           "formatted_address" => description,
           "geometry" => %{"location" => %{"lat" => lat, "lng" => lon}},
           "address_components" => components,
           "place_id" => place_id
         },
         options
       ) do
    components =
      @components
      |> Enum.reduce(%{}, fn component, acc ->
        Map.put(acc, component, extract_component(components, component))
      end)

    description =
      if Keyword.get(options, :fetch_place_details, @fetch_place_details) == true do
        do_fetch_place_details(place_id, options) || description
      else
        description
      end

    %Address{
      country: Map.get(components, "country"),
      locality: Map.get(components, "locality"),
      region: Map.get(components, "administrative_area_level_1"),
      description: description,
      geom: [lon, lat] |> Provider.coordinates(),
      postal_code: Map.get(components, "postal_code"),
      street: street_address(components),
      origin_id: "gm:" <> to_string(place_id)
    }
  end

  defp extract_component(components, key) do
    case components
         |> Enum.filter(fn component -> key in component["types"] end)
         |> Enum.map(& &1["long_name"]) do
      [] -> nil
      component -> hd(component)
    end
  end

  defp street_address(body) do
    if Map.has_key?(body, "street_number") && !is_nil(Map.get(body, "street_number")) do
      Map.get(body, "street_number") <> " " <> Map.get(body, "route")
    else
      Map.get(body, "route")
    end
  end

  defp do_fetch_place_details(place_id, options) do
    url = build_url(:place_details, %{place_id: place_id}, options)

    Logger.debug("Asking Google Maps for details with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"result" => %{"name" => name}, "status" => "OK"} <- body do
      name
    else
      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)

      %{"status" => "INVALID_REQUEST"} ->
        raise ArgumentError, message: "Invalid Request"

      %{"results" => [], "status" => "ZERO_RESULTS"} ->
        nil
    end
  end
end
