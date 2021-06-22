defmodule Mobilizon.Service.AddressTest do
  @moduledoc """
  Test representing addresses
  """
  use Mobilizon.DataCase
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Address, as: AddressRenderer
  import Mobilizon.Factory

  describe "render an address" do
    test "basic" do
      %Address{} = address = insert(:address)

      assert AddressRenderer.render_address(address) ==
               "#{address.description}, #{address.postal_code}, #{address.locality}, #{address.country}"
    end

    test "a house" do
      assert AddressRenderer.render_address(%Address{
               description: "somewhere",
               type: "house",
               postal_code: "35000",
               locality: "Rennes"
             }) ==
               "somewhere, 35000, Rennes"
    end

    test "a city" do
      assert AddressRenderer.render_address(%Address{
               description: "Rennes",
               type: "city",
               postal_code: "35000",
               locality: "Rennes"
             }) ==
               "Rennes (35000)"
    end

    test "a region" do
      assert AddressRenderer.render_address(%Address{
               description: "Ille et Vilaine",
               type: "administrative",
               postal_code: "",
               locality: ""
             }) ==
               "Ille et Vilaine"
    end

    test "only with description" do
      assert AddressRenderer.render_address(%Address{description: "somewhere"}) == "somewhere"
    end

    test "with no data" do
      assert_raise ArgumentError, "Invalid address", fn ->
        AddressRenderer.render_address(%Address{})
      end
    end
  end
end
