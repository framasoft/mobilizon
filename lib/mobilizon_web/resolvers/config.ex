defmodule MobilizonWeb.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls.
  """

  alias Mobilizon.Config

  @doc """
  Gets config.
  """
  def get_config(_parent, _params, _context) do
    {:ok,
     %{
       name: Config.instance_name(),
       registrations_open: Config.instance_registrations_open?(),
       description: Config.instance_description()
     }}
  end
end
