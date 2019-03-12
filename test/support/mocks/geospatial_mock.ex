defmodule Mobilizon.Mobilizon.Service.Geospatial.Mock do
  @moduledoc """
  Mock for Geospatial Provider implementations
  """
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Addresses.Address

  @behaviour Provider

  @impl Provider
  def geocode(_lon, _lat, _options \\ []), do: [%Address{}]

  @impl Provider
  def search(_q, _options \\ []), do: [%Address{}]
end
