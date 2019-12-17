defmodule MobilizonWeb.Schema.ConfigType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  alias MobilizonWeb.Resolvers.Config

  @desc "A config object"
  object :config do
    # Instance name
    field(:name, :string)
    field(:description, :string)

    field(:registrations_open, :boolean)
    field(:registrations_whitelist, :boolean)
    field(:demo_mode, :boolean)
    field(:country_code, :string)
    field(:location, :lonlat)
    field(:geocoding, :geocoding)
    field(:maps, :maps)
  end

  object :lonlat do
    field(:longitude, :float)
    field(:latitude, :float)
    field(:accuracy_radius, :integer)
  end

  object :geocoding do
    field(:autocomplete, :boolean)
    field(:provider, :string)
  end

  object :maps do
    field(:tiles, :tiles)
  end

  object :tiles do
    field(:endpoint, :string)
    field(:attribution, :string)
  end

  object :config_queries do
    @desc "Get the instance config"
    field :config, :config do
      resolve(&Config.get_config/3)
    end
  end
end
