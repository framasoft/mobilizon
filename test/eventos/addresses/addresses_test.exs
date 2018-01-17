defmodule Eventos.AddressesTest do
  use Eventos.DataCase

  alias Eventos.Addresses

  describe "addresses" do
    alias Eventos.Addresses.Address

    @valid_attrs %{addressCountry: "some addressCountry", addressLocality: "some addressLocality", addressRegion: "some addressRegion", description: "some description", floor: "some floor", postalCode: "some postalCode", streetAddress: "some streetAddress", geom: %Geo.Point{coordinates: {10, -10}, srid: 4326}}
    @update_attrs %{addressCountry: "some updated addressCountry", addressLocality: "some updated addressLocality", addressRegion: "some updated addressRegion", description: "some updated description", floor: "some updated floor", postalCode: "some updated postalCode", streetAddress: "some updated streetAddress", geom: %Geo.Point{coordinates: {20, -20}, srid: 4326}}
    @invalid_attrs %{addressCountry: nil, addressLocality: nil, addressRegion: nil, description: nil, floor: nil, postalCode: nil, streetAddress: nil, geom: nil}

    def address_fixture(attrs \\ %{}) do
      {:ok, address} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Addresses.create_address()

      address
    end

    test "list_addresses/0 returns all addresses" do
      address = address_fixture()
      assert Addresses.list_addresses() == [address]
    end

    test "get_address!/1 returns the address with given id" do
      address = address_fixture()
      assert Addresses.get_address!(address.id) == address
    end

    test "create_address/1 with valid data creates a address" do
      assert {:ok, %Address{} = address} = Addresses.create_address(@valid_attrs)
      assert address.addressCountry == "some addressCountry"
      assert address.addressLocality == "some addressLocality"
      assert address.addressRegion == "some addressRegion"
      assert address.description == "some description"
      assert address.floor == "some floor"
      assert address.postalCode == "some postalCode"
      assert address.streetAddress == "some streetAddress"
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Addresses.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      address = address_fixture()
      assert {:ok, address} = Addresses.update_address(address, @update_attrs)
      assert %Address{} = address
      assert address.addressCountry == "some updated addressCountry"
      assert address.addressLocality == "some updated addressLocality"
      assert address.addressRegion == "some updated addressRegion"
      assert address.description == "some updated description"
      assert address.floor == "some updated floor"
      assert address.postalCode == "some updated postalCode"
      assert address.streetAddress == "some updated streetAddress"
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = address_fixture()
      assert {:error, %Ecto.Changeset{}} = Addresses.update_address(address, @invalid_attrs)
      assert address == Addresses.get_address!(address.id)
    end

    test "delete_address/1 deletes the address" do
      address = address_fixture()
      assert {:ok, %Address{}} = Addresses.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Addresses.get_address!(address.id) end
    end

    test "change_address/1 returns a address changeset" do
      address = address_fixture()
      assert %Ecto.Changeset{} = Addresses.change_address(address)
    end
  end
end
