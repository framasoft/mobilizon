defmodule MobilizonWeb.Resolvers.Address do
  @moduledoc """
  Handles the comment-related GraphQL calls
  """
  require Logger
  alias Mobilizon.Addresses
  alias Mobilizon.Service.Geospatial

  def search(_parent, %{query: query}, %{context: %{ip: ip}}) do
    country = Geolix.lookup(ip) |> Map.get(:country, nil)

    local_addresses = Task.async(fn -> Addresses.search_addresses(query, country: country) end)

    remote_addresses = Task.async(fn -> Geospatial.service().search(query) end)

    addresses = Task.await(local_addresses) ++ Task.await(remote_addresses)

    {:ok, addresses}
  end

  def reverse_geocode(_parent, %{longitude: longitude, latitude: latitude}, %{context: %{ip: ip}}) do
    country = Geolix.lookup(ip) |> Map.get(:country, nil)

    local_addresses =
      Task.async(fn -> Addresses.reverse_geocode(longitude, latitude, country: country) end)

    remote_addresses = Task.async(fn -> Geospatial.service().geocode(longitude, latitude) end)

    addresses = Task.await(local_addresses) ++ Task.await(remote_addresses)

    {:ok, addresses}
  end
end
