defmodule MobilizonWeb.Schema.AddressType do
  @moduledoc """
  Schema representation for Address
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers

  object :physical_address do
    field(:type, :address_type)
    field(:geom, :point)
    field(:floor, :string)
    field(:streetAddress, :string)
    field(:addressLocality, :string)
    field(:postalCode, :string)
    field(:addressRegion, :string)
    field(:addressCountry, :string)
    field(:description, :string)
    field(:name, :string)
  end

  object :phone_address do
    field(:type, :address_type)
    field(:phone, :string)
    field(:info, :string)
  end

  object :online_address do
    field(:type, :address_type)
    field(:url, :string)
    field(:info, :string)
  end

  @desc "The list of types an address can be"
  enum :address_type do
    value(:physical, description: "The address is physical, like a postal address")
    value(:url, description: "The address is on the Web, like an URL")
    value(:phone, description: "The address is a phone number for a conference")
    value(:other, description: "The address is something else")
  end

  object :address_queries do
    @desc "Search for an address"
    field :search_address, type: list_of(:physical_address) do
      arg(:query, non_null(:string))

      resolve(&Resolvers.Address.search/3)
    end

    @desc "Reverse geocode coordinates"
    field :reverse_geocode, type: list_of(:physical_address) do
      arg(:longitude, non_null(:float))
      arg(:latitude, non_null(:float))

      resolve(&Resolvers.Address.reverse_geocode/3)
    end
  end
end
