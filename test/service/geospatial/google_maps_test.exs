defmodule Mobilizon.Service.Geospatial.GoogleMapsTest do
  use Mobilizon.DataCase

  import Mox

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.GoogleMaps
  alias Mobilizon.Service.HTTP.GeospatialClient.Mock

  describe "search address" do
    test "without API Key triggers an error" do
      assert_raise ArgumentError, "API Key required to use Google Maps", fn ->
        GoogleMaps.search("10 Rue Jangot")
      end
    end

    test "triggers an error with an invalid API Key" do
      data =
        File.read!("test/fixtures/geospatial/google_maps/api_key_invalid.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://maps.googleapis.com/maps/api/geocode/json?limit=10&key=secret_key&language=en&address=10%20rue%20Jangot"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert_raise ArgumentError, "The provided API key is invalid.", fn ->
        GoogleMaps.search("10 rue Jangot", api_key: "secret_key")
      end
    end

    test "returns a valid address from search" do
      data =
        File.read!("test/fixtures/geospatial/google_maps/search.json")
        |> Jason.decode!()

      data_2 =
        File.read!("test/fixtures/geospatial/google_maps/search_2.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 3, fn
        %{
          method: :get,
          url:
            "https://maps.googleapis.com/maps/api/geocode/json?limit=10&key=toto&language=en&address=10%20rue%20Jangot"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}

        %{
          method: :get,
          url: _url
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data_2}}
      end)

      assert %Address{
               locality: "Lyon",
               description: "10 Rue Jangot",
               region: "Auvergne-Rhône-Alpes",
               country: "France",
               postal_code: "69007",
               street: "10 Rue Jangot",
               geom: %Geo.Point{
                 coordinates: {4.8424032, 45.75164940000001},
                 properties: %{},
                 srid: 4326
               },
               origin_id: "gm:ChIJtW0QikTq9EcRLI4Vy6bRx0U"
             } ==
               GoogleMaps.search("10 rue Jangot",
                 api_key: "toto"
               )
               |> hd
    end

    test "returns a valid address from reverse geocode" do
      data =
        File.read!("test/fixtures/geospatial/google_maps/geocode.json")
        |> Jason.decode!()

      data_2 =
        File.read!("test/fixtures/geospatial/google_maps/geocode_2.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 3, fn
        %{
          method: :get,
          url:
            "https://maps.googleapis.com/maps/api/geocode/json?limit=10&key=toto&language=en&latlng=45.751718,4.842569&result_type=street_address"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}

        %{
          method: :get,
          url: _url
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data_2}}
      end)

      assert %Address{
               locality: "Lyon",
               description: "10bis Rue Jangot",
               region: "Auvergne-Rhône-Alpes",
               country: "France",
               postal_code: "69007",
               street: "10bis Rue Jangot",
               geom: %Geo.Point{
                 coordinates: {4.8424966, 45.751725},
                 properties: %{},
                 srid: 4326
               },
               origin_id: "gm:ChIJrW0QikTq9EcR96jk2OnO75w"
             } ==
               GoogleMaps.geocode(4.842569, 45.751718, api_key: "toto")
               |> hd
    end
  end
end
