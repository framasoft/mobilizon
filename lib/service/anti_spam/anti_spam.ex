defmodule Mobilizon.Service.AntiSpam do
  @moduledoc """
  Module to load the service adapter defined inside the configuration.

  See `Mobilizon.Service.AntiSpam.Provider`.
  """

  @doc """
  Returns the appropriate service adapter.

  According to the config behind
    `config :mobilizon, Mobilizon.Service.AntiSpam,
       service: Mobilizon.Service.AntiSpam.Module`
  """
  @spec service :: module
  def service, do: get_in(Application.get_env(:mobilizon, __MODULE__), [:service])
end
