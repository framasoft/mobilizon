defmodule Mobilizon.Service.Geospatial.Nominatim do
  @moduledoc """
  [Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) backend.
  """
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Addresses.Address
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
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)
    Logger.debug("Asking Nominatim for geocode with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url),
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
    url = build_url(:search, %{q: q}, options)
    Logger.debug("Asking Nominatim for addresses with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url),
         {:ok, body} <- Poison.decode(body) do
      Enum.map(body, fn entry -> process_data(entry) end)
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
      addressCountry: Map.get(address, "country"),
      addressLocality: Map.get(address, "city"),
      addressRegion: Map.get(address, "state"),
      description: Map.get(body, "display_name"),
      floor: Map.get(address, "floor"),
      geom: [Map.get(body, "lon"), Map.get(body, "lat")] |> Provider.coordinates(),
      postalCode: Map.get(address, "postcode"),
      streetAddress: street_address(address)
    }
  end

  @spec street_address(map()) :: String.t()
  defp street_address(body) do
    if Map.has_key?(body, "house_number") do
      Map.get(body, "house_number") <> " " <> Map.get(body, "road")
    else
      Map.get(body, "road")
    end
  end
end
