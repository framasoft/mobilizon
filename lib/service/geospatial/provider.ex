defmodule Mobilizon.Service.Geospatial.Provider do
  @moduledoc """
  Provider Behaviour for Geospatial stuff.

  ## Supported backends

  * `Mobilizon.Service.Geospatial.Nominatim` [🔗](https://wiki.openstreetmap.org/wiki/Nominatim)
  * `Mobilizon.Service.Geospatial.Photon` [🔗](https://photon.komoot.de)
  * `Mobilizon.Service.Geospatial.Addok` [🔗](https://github.com/addok/addok)
  * `Mobilizon.Service.Geospatial.MapQuest` [🔗](https://developer.mapquest.com/documentation/open/)
  * `Mobilizon.Service.Geospatial.GoogleMaps` [🔗](https://developers.google.com/maps/documentation/geocoding/intro)


  ## Shared options

  * `:user_agent` User-Agent string to send to the backend. Defaults to `"Mobilizon"`
  * `:lang` Lang in which to prefer results. Used as a request parameter or through an `Accept-Language` HTTP header.
     Defaults to `"en"`.
  * `:limit` Maximum limit for the number of results returned by the backend. Defaults to `10`
  * `:api_key` Allows to override the API key (if the backend requires one) set inside the configuration.
  * `:endpoint` Allows to override the endpoint set inside the configuration
  """

  alias Mobilizon.Addresses.Address

  @doc """
  Get an address from longitude and latitude coordinates.

  ## Options

  Most backends implement all of [the shared options](#module-shared-options).

  ## Examples

      iex> geocode(48.11, -1.77)
      %Address{}
  """
  @callback geocode(longitude :: number(), latitude :: number(), options :: keyword()) ::
              list(Address.t())

  @doc """
  Search for an address

  ## Options

  In addition to [the shared options](#module-shared-options), `c:search/2` also accepts the following options:

  * `coords` Map of coordinates (ex: `%{lon: 48.11, lat: -1.77}`) allowing to give a geographic priority to the search.
    Defaults to `nil`

  ## Examples

      iex> search("10 rue Jangot")
      %Address{}
  """
  @callback search(address :: String.t(), options :: keyword()) :: list(Address.t())

  @doc """
  Returns a `Geo.Point` for given coordinates
  """
  @spec coordinates(list(number()), number()) :: Geo.Point.t()
  def coordinates(coords, srid \\ 4326)

  def coordinates([x, y], srid) when is_number(x) and is_number(y),
    do: %Geo.Point{coordinates: {x, y}, srid: srid}

  def coordinates([x, y], srid) when is_bitstring(x) and is_bitstring(y),
    do: %Geo.Point{coordinates: {String.to_float(x), String.to_float(y)}, srid: srid}

  @spec coordinates(any()) :: nil
  def coordinates(_, _), do: nil
end
