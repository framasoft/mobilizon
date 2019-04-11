defmodule MobilizonWeb.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls
  """

  import Mobilizon.CommonConfig

  @doc """
  Get config
  """
  def get_config(_parent, _params, _context) do
    {:ok,
     %{
       name: instance_name(),
       registrations_open: registrations_open?(),
       description: instance_description()
     }}
  end
end
