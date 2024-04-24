defmodule Mobilizon.Service.Geospatial.Hat do
  @moduledoc """
  Hat backend.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Addok
  alias Mobilizon.Service.Geospatial.Nominatim
  alias Mobilizon.Service.Geospatial.Provider
  require Logger

  @behaviour Provider

  @impl Provider
  @doc """
  Hat implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    tasks = [
      Task.async(fn -> Addok.geocode(lon, lat, options) end),
      Task.async(fn -> Nominatim.geocode(lon, lat, options) end)
    ]

    [addrlist1, addrlist2] = Task.await_many(tasks, 12_000)
    addrlist2 ++ addrlist1
  end

  @impl Provider
  @doc """
  Hat implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    tasks = [
      Task.async(fn -> Addok.search(q, options) end),
      Task.async(fn -> Nominatim.search(q, options) end)
    ]

    [addrlist1, addrlist2] = Task.await_many(tasks, 12_000)
    addrlist2 ++ addrlist1
  end
end
