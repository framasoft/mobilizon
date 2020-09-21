defmodule Mobilizon.Service.Geospatial.MapQuest do
  @moduledoc """
  [MapQuest](https://developer.mapquest.com/documentation) backend.

  ## Options
  In addition to the [the shared options](Mobilizon.Service.Geospatial.Provider.html#module-shared-options),
  MapQuest methods support the following options:
    * `:open_data` Whether to use [Open Data or Licenced Data](https://developer.mapquest.com/documentation/open/).
      Defaults to `true`
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.GeospatialClient

  require Logger

  @behaviour Provider

  @api_key Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])

  @api_key_missing_message "API Key required to use MapQuest"

  @impl Provider
  @doc """
  MapQuest implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    api_key = Keyword.get(options, :api_key, @api_key)
    limit = Keyword.get(options, :limit, 10)
    open_data = Keyword.get(options, :open_data, true)

    prefix = if open_data, do: "open", else: "www"

    if is_nil(api_key), do: raise(ArgumentError, message: @api_key_missing_message)

    with {:ok, %{status: 200, body: body}} <-
           GeospatialClient.get(
             "https://#{prefix}.mapquestapi.com/geocoding/v1/reverse?key=#{api_key}&location=#{
               lat
             },#{lon}&maxResults=#{limit}"
           ),
         %{"results" => results, "info" => %{"statuscode" => 0}} <- body do
      results |> Enum.map(&process_data/1)
    else
      {:ok, %{status: 403, body: err}} ->
        raise(ArgumentError, message: err)
    end
  end

  @impl Provider
  @doc """
  MapQuest implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    limit = Keyword.get(options, :limit, 10)
    api_key = Keyword.get(options, :api_key, @api_key)

    open_data = Keyword.get(options, :open_data, true)

    prefix = if open_data, do: "open", else: "www"

    if is_nil(api_key), do: raise(ArgumentError, message: @api_key_missing_message)

    url =
      "https://#{prefix}.mapquestapi.com/geocoding/v1/address?key=#{api_key}&location=#{
        URI.encode(q)
      }&maxResults=#{limit}"

    Logger.debug("Asking MapQuest for addresses with #{url}")

    with {:ok, %{status: 200, body: body}} <- GeospatialClient.get(url),
         %{"results" => results, "info" => %{"statuscode" => 0}} <- body do
      results |> Enum.map(&process_data/1)
    else
      {:ok, %{status: 403, body: err}} ->
        raise(ArgumentError, message: err)
    end
  end

  defp process_data(
         %{
           "locations" => addresses,
           "providedLocation" => %{"latLng" => %{"lat" => lat, "lng" => lng}}
         } = _body
       ) do
    case addresses do
      [] -> nil
      addresses -> addresses |> hd |> produce_address(lat, lng)
    end
  end

  defp process_data(%{"locations" => addresses}) do
    case addresses do
      [] -> nil
      addresses -> addresses |> hd |> produce_address()
    end
  end

  defp produce_address(%{"latLng" => %{"lat" => lat, "lng" => lng}} = address) do
    produce_address(address, lat, lng)
  end

  defp produce_address(address, lat, lng) do
    %Address{
      country: Map.get(address, "adminArea1"),
      locality: Map.get(address, "adminArea5"),
      region: Map.get(address, "adminArea3"),
      description: Map.get(address, "street"),
      geom: [lng, lat] |> Provider.coordinates(),
      postal_code: Map.get(address, "postalCode"),
      street: Map.get(address, "street")
    }
  end
end
