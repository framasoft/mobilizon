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
    field(:country_code, :string)
    field(:location, :lonlat)
  end

  object :lonlat do
    field(:longitude, :float)
    field(:latitude, :float)
    field(:accuracy_radius, :integer)
  end

  object :config_queries do
    @desc "Get the instance config"
    field :config, :config do
      resolve(&Config.get_config/3)
    end
  end
end
