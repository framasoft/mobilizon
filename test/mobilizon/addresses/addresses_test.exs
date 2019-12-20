defmodule Mobilizon.AddressesTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  alias Mobilizon.Addresses

  describe "addresses" do
    alias Mobilizon.Addresses.Address

    @valid_attrs %{
      country: "some addressCountry",
      locality: "some addressLocality",
      region: "some addressRegion",
      description: "some description",
      postal_code: "some postalCode",
      street: "some streetAddress",
      geom: %Geo.Point{coordinates: {10, -10}, srid: 4326}
    }
    @update_attrs %{
      country: "some updated addressCountry",
      locality: "some updated addressLocality",
      region: "some updated addressRegion",
      description: "some updated description",
      postal_code: "some updated postalCode",
      street: "some updated streetAddress",
      geom: %Geo.Point{coordinates: {20, -20}, srid: 4326}
    }

    # @invalid_attrs %{
    #   addressCountry: nil,
    #   addressLocality: nil,
    #   addressRegion: nil,
    #   description: nil,
    #   postalCode: nil,
    #   streetAddress: nil,
    #   geom: nil
    # }

    test "list_addresses/0 returns all addresses" do
      address = insert(:address)
      assert [address.id] == Addresses.list_addresses() |> Enum.map(& &1.id)
    end

    test "get_address!/1 returns the address with given id" do
      address = insert(:address)
      assert Addresses.get_address!(address.id).id == address.id
    end

    test "create_address/1 with valid data creates a address" do
      assert {:ok, %Address{} = address} = Addresses.create_address(@valid_attrs)
      assert address.country == "some addressCountry"
      assert address.locality == "some addressLocality"
      assert address.region == "some addressRegion"
      assert address.description == "some description"
      assert address.postal_code == "some postalCode"
      assert address.street == "some streetAddress"
    end

    test "update_address/2 with valid data updates the address" do
      address = insert(:address)
      assert {:ok, %Address{} = address} = Addresses.update_address(address, @update_attrs)
      assert address.country == "some updated addressCountry"
      assert address.locality == "some updated addressLocality"
      assert address.region == "some updated addressRegion"
      assert address.description == "some updated description"
      assert address.postal_code == "some updated postalCode"
      assert address.street == "some updated streetAddress"
    end

    test "delete_address/1 deletes the address" do
      address = insert(:address)
      assert {:ok, %Address{}} = Addresses.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Addresses.get_address!(address.id) end
    end
  end
end
