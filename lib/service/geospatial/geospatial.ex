defmodule Mobilizon.Service.Geospatial do
  @moduledoc """
  Module to load the service adapter defined inside the configuration.

  See `Mobilizon.Service.Geospatial.Provider`.
  """

  @doc """
  Returns the appropriate service adapter.

  According to the config behind
    `config :mobilizon, Mobilizon.Service.Geospatial,
       service: Mobilizon.Service.Geospatial.Module`
  """
  @spec service :: module
  def service, do: get_in(Application.get_env(:mobilizon, __MODULE__), [:service])
end
