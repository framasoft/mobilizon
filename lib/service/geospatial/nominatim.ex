defmodule Mobilizon.Service.Geospatial.Nominatim do
  @moduledoc """
  [Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) backend.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Config

  require Logger

  @behaviour Provider

  @endpoint Application.get_env(:mobilizon, __MODULE__) |> get_in([:endpoint])
  @api_key Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, Config.instance_user_agent())
    headers = [{"User-Agent", user_agent}]
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)
    Logger.debug("Asking Nominatim for geocode with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, headers),
         {:ok, body} <- Poison.decode(body) do
      [process_data(body)]
    end
  end

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, Config.instance_user_agent())
    headers = [{"User-Agent", user_agent}]
    url = build_url(:search, %{q: q}, options)
    Logger.debug("Asking Nominatim for addresses with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, headers),
         {:ok, body} <- Poison.decode(body) do
      body |> Enum.map(fn entry -> process_data(entry) end) |> Enum.filter(& &1)
    end
  end

  @spec build_url(atom(), map(), list()) :: String.t()
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    endpoint = Keyword.get(options, :endpoint, @endpoint)
    api_key = Keyword.get(options, :api_key, @api_key)

    url =
      case method do
        :search ->
          "#{endpoint}/search?format=jsonv2&q=#{URI.encode(args.q)}&limit=#{limit}&accept-language=#{
            lang
          }&addressdetails=1"

        :geocode ->
          "#{endpoint}/reverse?format=jsonv2&lat=#{args.lat}&lon=#{args.lon}&addressdetails=1"
      end

    if is_nil(api_key), do: url, else: url <> "&key=#{api_key}"
  end

  @spec process_data(map()) :: Address.t()
  defp process_data(%{"address" => address} = body) do
    %Address{
      country: Map.get(address, "country"),
      locality: Map.get(address, "city"),
      region: Map.get(address, "state"),
      description: description(body),
      geom: [Map.get(body, "lon"), Map.get(body, "lat")] |> Provider.coordinates(),
      postal_code: Map.get(address, "postcode"),
      street: street_address(address),
      origin_id: "osm:" <> to_string(Map.get(body, "osm_id"))
    }
  rescue
    error in ArgumentError ->
      Logger.warn(inspect(error))

      nil
  end

  @spec street_address(map()) :: String.t()
  defp street_address(body) do
    road =
      cond do
        Map.has_key?(body, "road") ->
          Map.get(body, "road")

        Map.has_key?(body, "road") ->
          Map.get(body, "road")

        Map.has_key?(body, "pedestrian") ->
          Map.get(body, "pedestrian")

        true ->
          ""
      end

    Map.get(body, "house_number", "") <> " " <> road
  end

  @address29_classes ["amenity", "shop", "tourism", "leisure"]
  @address29_categories ["office"]

  @spec description(map()) :: String.t()
  defp description(body) do
    if !Map.has_key?(body, "display_name") do
      Logger.warn("Address has no display name")
      raise ArgumentError, message: "Address has no display_name"
    end

    description = Map.get(body, "display_name")
    address = Map.get(body, "address")

    if (Map.get(body, "category") in @address29_categories or
          Map.get(body, "class") in @address29_classes) and Map.has_key?(address, "address29") do
      Map.get(address, "address29")
    else
      description
    end
  end
end
