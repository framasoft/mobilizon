defmodule Mobilizon.Federation.ActivityStream.Converter.AddressTest do
  use Mobilizon.DataCase

  alias Mobilizon.Addresses.Address

  alias Mobilizon.Federation.ActivityStream.Converter.Address, as: AddressConverter

  describe "address to AS" do
    test "valid address to as" do
      data =
        AddressConverter.model_to_as(%Address{
          country: "France",
          locality: "Lyon",
          description: "Locaux'Motiv",
          postal_code: "69007",
          street: "10Bis Rue Jangot"
        })

      assert is_map(data)
      assert data["type"] == "Place"
      assert data["name"] == "Locaux'Motiv"
      assert data["address"]["type"] == "PostalAddress"
      assert data["address"]["addressLocality"] == "Lyon"
      assert data["address"]["postalCode"] == "69007"
      assert data["address"]["addressCountry"] == "France"
      assert data["address"]["streetAddress"] == "10Bis Rue Jangot"
    end
  end

  describe "AS to Address" do
    test "basic AS data to model" do
      address =
        AddressConverter.as_to_model_data(%{
          "type" => "Place",
          "name" => "Federazione Anarchica Torinese",
          "address" => "corso Palermo 46",
          "latitude" => nil,
          "longitude" => nil
        })

      assert address["description"] == "Federazione Anarchica Torinese"
      assert address["street"] == "corso Palermo 46"
      assert address["locality"] == nil
      assert address["geom"] == nil
    end

    test "AS data with PostalAddress to model" do
      address =
        AddressConverter.as_to_model_data(%{
          "type" => "Place",
          "name" => "Federazione Anarchica Torinese",
          "address" => %{
            "streetAddress" => "Corso Palermo, 46",
            "addressCountry" => "Italia",
            "postalCode" => "10152",
            "addressLocality" => "Torino"
          },
          "latitude" => 45.08281,
          "longitude" => 7.69311
        })

      assert address["description"] == "Federazione Anarchica Torinese"
      assert address["street"] == "Corso Palermo, 46"
      assert address["locality"] == "Torino"
      assert address["postal_code"] == "10152"
      assert address["country"] == "Italia"

      assert address["geom"] == %Geo.Point{
               coordinates: {7.69311, 45.08281},
               srid: 4326
             }
    end
  end
end
