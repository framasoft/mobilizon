defmodule Mobilizon.Service.Geospatial.Mock do
  @moduledoc """
  Mock for Geospatial Provider implementations.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider

  @behaviour Provider

  @impl Provider
  def geocode(_lon, _lat, _options \\ [])
  def geocode(45.75, 4.85, _options), do: [%Address{description: "10 rue Jangot, Lyon"}]
  def geocode(_lon, _lat, _options), do: [%Address{description: "Anywhere"}]

  @impl Provider
  def search(_q, _options \\ []), do: [%Address{description: "10 rue Jangot, Lyon"}]
end
