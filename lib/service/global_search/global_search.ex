defmodule Mobilizon.Service.GlobalSearch do
  @moduledoc """
  Module to load the service adapter defined inside the configuration.

  See `Mobilizon.Service.GlobalSearch.Provider`.
  """

  @doc """
  Returns the appropriate service adapter.

  According to the config behind
    `config :mobilizon, Mobilizon.Service.GlobalSearch,
       service: Mobilizon.Service.GlobalSearch.Module`
  """
  @spec service :: module
  def service, do: get_in(Application.get_env(:mobilizon, __MODULE__), [:service])
end
