defmodule Mobilizon.Service.Geospatial.GoogleMaps do
  @moduledoc """
  Google Maps [Geocoding service](https://developers.google.com/maps/documentation/geocoding/intro)

  Note: Endpoint is hardcoded to Google Maps API
  """
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Addresses.Address
  require Logger

  @behaviour Provider

  @api_key Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])

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

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url),
         {:ok, %{"results" => results, "status" => "OK"}} <- Poison.decode(body) do
      Enum.map(results, &process_data/1)
    else
      {:ok, %{"status" => "REQUEST_DENIED", "error_message" => error_message}} ->
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

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url),
         {:ok, %{"results" => results, "status" => "OK"}} <- Poison.decode(body) do
      Enum.map(results, fn entry -> process_data(entry) end)
    else
      {:ok, %{"status" => "REQUEST_DENIED", "error_message" => error_message}} ->
        raise ArgumentError, message: to_string(error_message)
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

    case method do
      :search ->
        url <> "&address=#{URI.encode(args.q)}"

      :geocode ->
        url <> "&latlng=#{args.lat},#{args.lon}"
    end
  end

  defp process_data(%{
         "formatted_address" => description,
         "geometry" => %{"location" => %{"lat" => lat, "lng" => lon}},
         "address_components" => components
       }) do
    components =
      @components
      |> Enum.reduce(%{}, fn component, acc ->
        Map.put(acc, component, extract_component(components, component))
      end)

    %Address{
      country: Map.get(components, "country"),
      locality: Map.get(components, "locality"),
      region: Map.get(components, "administrative_area_level_1"),
      description: description,
      floor: nil,
      geom: [lon, lat] |> Provider.coordinates(),
      postal_code: Map.get(components, "postal_code"),
      street: street_address(components)
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
end
