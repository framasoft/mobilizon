defmodule MobilizonWeb.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls.
  """

  alias Mobilizon.Config
  alias Geolix.Adapter.MMDB2.Record.{Country, Location}

  @doc """
  Gets config.
  """
  def get_config(_parent, _params, %{
        context: %{ip: ip}
      }) do
    geolix = Geolix.lookup(ip)

    country_code =
      case geolix.city do
        %{country: %Country{iso_code: country_code}} -> String.downcase(country_code)
        _ -> nil
      end

    location =
      case geolix.city do
        %{location: %Location{} = location} -> Map.from_struct(location)
        _ -> nil
      end

    {:ok,
     %{
       name: Config.instance_name(),
       registrations_open: Config.instance_registrations_open?(),
       description: Config.instance_description(),
       location: location,
       country_code: country_code
     }}
  end
end
