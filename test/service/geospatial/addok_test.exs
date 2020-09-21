defmodule Mobilizon.Service.Geospatial.AddokTest do
  use Mobilizon.DataCase

  import Mox

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Addok
  alias Mobilizon.Service.HTTP.GeospatialClient.Mock

  describe "search address" do
    test "returns a valid address from search" do
      data =
        File.read!("test/fixtures/geospatial/addok/search.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://api-adresse.data.gouv.fr/search/?q=10%20rue%20Jangot&limit=10"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert %Address{
               country: "France",
               region: "69, Rhône, Auvergne-Rhône-Alpes",
               locality: "Lyon",
               description: "10 Rue Jangot",
               postal_code: "69007",
               street: "10 Rue Jangot",
               geom: %Geo.Point{coordinates: {4.842569, 45.751718}, properties: %{}, srid: 4326}
             } == Addok.search("10 rue Jangot") |> hd
    end

    test "returns a valid address from reverse geocode" do
      data =
        File.read!("test/fixtures/geospatial/addok/geocode.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://api-adresse.data.gouv.fr/reverse/?lon=4.842569&lat=45.751718&limit=10"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert %Address{
               country: "France",
               region: "69, Rhône, Auvergne-Rhône-Alpes",
               locality: "Lyon",
               description: "10 Rue Jangot",
               postal_code: "69007",
               street: "10 Rue Jangot",
               geom: %Geo.Point{coordinates: {4.842569, 45.751718}, properties: %{}, srid: 4326}
             } == Addok.geocode(4.842569, 45.751718) |> hd
    end
  end
end
