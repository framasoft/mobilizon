defmodule MobilizonWeb.Resolvers.Address do
  @moduledoc """
  Handles the comment-related GraphQL calls
  """
  require Logger
  alias Mobilizon.Addresses
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial

  @doc """
  Search an address
  """
  @spec search(map(), map(), map()) :: {:ok, list(Address.t())}
  def search(_parent, %{query: query, page: _page, limit: _limit}, %{context: %{ip: ip}}) do
    country = ip |> Geolix.lookup() |> Map.get(:country, nil)

    local_addresses = Task.async(fn -> Addresses.search_addresses(query, country: country) end)

    remote_addresses = Task.async(fn -> Geospatial.service().search(query) end)

    addresses = Task.await(local_addresses) ++ Task.await(remote_addresses)

    # If we have results with same origin_id than those locally saved, don't return them
    addresses =
      Enum.reduce(addresses, %{}, fn address, addresses ->
        if Map.has_key?(addresses, address.origin_id) && !is_nil(address.url) do
          addresses
        else
          Map.put(addresses, address.origin_id, address)
        end
      end)

    addresses = Map.values(addresses)

    {:ok, addresses}
  end

  @doc """
  Reverse geocode some coordinates
  """
  @spec reverse_geocode(map(), map(), map()) :: {:ok, list(Address.t())}
  def reverse_geocode(_parent, %{longitude: longitude, latitude: latitude}, %{context: %{ip: ip}}) do
    country = ip |> Geolix.lookup() |> Map.get(:country, nil)

    local_addresses =
      Task.async(fn -> Addresses.reverse_geocode(longitude, latitude, country: country) end)

    remote_addresses = Task.async(fn -> Geospatial.service().geocode(longitude, latitude) end)

    addresses = Task.await(local_addresses) ++ Task.await(remote_addresses)

    {:ok, addresses}
  end
end
