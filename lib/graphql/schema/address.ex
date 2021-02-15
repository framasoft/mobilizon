defmodule Mobilizon.GraphQL.Schema.AddressType do
  @moduledoc """
  Schema representation for Address
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Address

  @desc """
  An address object
  """
  object :address do
    field(:geom, :point, description: "The geocoordinates for the point where this address is")
    field(:street, :string, description: "The address's street name (with number)")
    field(:locality, :string, description: "The address's locality")
    field(:postal_code, :string, description: "The address's postal code")
    field(:region, :string, description: "The address's region")
    field(:country, :string, description: "The address's country")
    field(:description, :string, description: "The address's description")
    field(:type, :string, description: "The address's type")
    field(:url, :string, description: "The address's URL")
    field(:id, :id, description: "The address's ID")
    field(:origin_id, :string, description: "The address's original ID from the provider")
  end

  @desc """
  A phone address
  """
  object :phone_address do
    field(:phone, :string, description: "The phone number")
    field(:info, :string, description: "Additional information about the phone number")
  end

  @desc """
  An online address
  """
  object :online_address do
    field(:url, :string)
    field(:info, :string)
  end

  @desc """
  An address input
  """
  input_object :address_input do
    field(:geom, :point, description: "The geocoordinates for the point where this address is")
    field(:street, :string, description: "The address's street name (with number)")
    field(:locality, :string, description: "The address's locality")
    field(:postal_code, :string, description: "The address's postal code")
    field(:region, :string, description: "The address's region")
    field(:country, :string, description: "The address's country")
    field(:description, :string, description: "The address's description")
    field(:type, :string, description: "The address's type")
    field(:url, :string, description: "The address's URL")
    field(:id, :id, description: "The address's ID")
    field(:origin_id, :string, description: "The address's original ID from the provider")
  end

  @desc """
  A list of possible values for the type option to search an address.

  Results may vary depending on the geocoding provider.
  """
  enum :address_search_type do
    value(:administrative, description: "Administrative results (cities, regions,...)")
  end

  object :address_queries do
    @desc "Search for an address"
    field :search_address, type: list_of(:address) do
      arg(:query, non_null(:string))

      arg(:locale, :string,
        default_value: "en",
        description: "The user's locale. Geocoding backends will make use of this value."
      )

      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated search results list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of search results per page")

      arg(:type, :address_search_type, description: "Filter by type of results")

      resolve(&Address.search/3)
    end

    @desc "Reverse geocode coordinates"
    field :reverse_geocode, type: list_of(:address) do
      arg(:longitude, non_null(:float), description: "Geographical longitude (using WGS 84)")
      arg(:latitude, non_null(:float), description: "Geographical latitude (using WGS 84)")
      arg(:zoom, :integer, default_value: 15, description: "Zoom level")

      arg(:locale, :string,
        default_value: "en",
        description: "The user's locale. Geocoding backends will make use of this value."
      )

      resolve(&Address.reverse_geocode/3)
    end
  end
end
