defmodule Mobilizon.GraphQL.Schema.AddressType do
  @moduledoc """
  Schema representation for Address
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Address

  object :address do
    field(:geom, :point, description: "The geocoordinates for the point where this address is")
    field(:street, :string, description: "The address's street name (with number)")
    field(:locality, :string, description: "The address's locality")
    field(:postal_code, :string)
    field(:region, :string)
    field(:country, :string)
    field(:description, :string)
    field(:type, :string)
    field(:url, :string)
    field(:id, :id)
    field(:origin_id, :string)
  end

  object :phone_address do
    field(:phone, :string)
    field(:info, :string)
  end

  object :online_address do
    field(:url, :string)
    field(:info, :string)
  end

  input_object :address_input do
    # Either a full picture object
    field(:geom, :point, description: "The geocoordinates for the point where this address is")
    field(:street, :string, description: "The address's street name (with number)")
    field(:locality, :string, description: "The address's locality")
    field(:postal_code, :string)
    field(:region, :string)
    field(:country, :string)
    field(:description, :string)
    field(:url, :string)
    field(:type, :string)
    field(:id, :id)
    field(:origin_id, :string)
  end

  object :address_queries do
    @desc "Search for an address"
    field :search_address, type: list_of(:address) do
      arg(:query, non_null(:string))
      arg(:locale, :string, default_value: "en")
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)

      resolve(&Address.search/3)
    end

    @desc "Reverse geocode coordinates"
    field :reverse_geocode, type: list_of(:address) do
      arg(:longitude, non_null(:float))
      arg(:latitude, non_null(:float))
      arg(:zoom, :integer, default_value: 15)
      arg(:locale, :string, default_value: "en")

      resolve(&Address.reverse_geocode/3)
    end
  end
end
