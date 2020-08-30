defmodule Mobilizon.Service.Geospatial.MapQuestTest do
  use Mobilizon.DataCase

  import Mox

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.MapQuest
  alias Mobilizon.Service.HTTP.GeospatialClient.Mock

  describe "search address" do
    test "without API Key triggers an error" do
      assert_raise ArgumentError, "API Key required to use MapQuest", fn ->
        MapQuest.search("10 Rue Jangot")
      end
    end

    test "triggers an error with an invalid API Key" do
      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://open.mapquestapi.com/geocoding/v1/address?key=secret_key&location=10%20rue%20Jangot&maxResults=10"
        },
        _opts ->
          {:ok,
           %Tesla.Env{status: 403, body: "The AppKey submitted with this request is invalid."}}
      end)

      assert_raise ArgumentError, "The AppKey submitted with this request is invalid.", fn ->
        MapQuest.search("10 rue Jangot", api_key: "secret_key")
      end
    end

    test "returns a valid address from search" do
      data =
        File.read!("test/fixtures/geospatial/map_quest/search.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://open.mapquestapi.com/geocoding/v1/address?key=secret_key&location=10%20rue%20Jangot&maxResults=10"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert %Address{
               locality: "Lyon",
               description: "10 Rue Jangot",
               region: "Auvergne-Rhône-Alpes",
               country: "FR",
               postal_code: "69007",
               street: "10 Rue Jangot",
               geom: %Geo.Point{
                 coordinates: {4.842566, 45.751714},
                 properties: %{},
                 srid: 4326
               }
             } ==
               MapQuest.search("10 rue Jangot", api_key: "secret_key")
               |> hd
    end

    test "returns a valid address from reverse geocode" do
      data =
        File.read!("test/fixtures/geospatial/map_quest/geocode.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://open.mapquestapi.com/geocoding/v1/reverse?key=secret_key&location=45.751718,4.842569&maxResults=10"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert %Address{
               locality: "Lyon",
               description: "10 Rue Jangot",
               region: "Auvergne-Rhône-Alpes",
               country: "FR",
               postal_code: "69007",
               street: "10 Rue Jangot",
               geom: %Geo.Point{
                 coordinates: {4.842569, 45.751718},
                 properties: %{},
                 srid: 4326
               }
             } ==
               MapQuest.geocode(4.842569, 45.751718, api_key: "secret_key")
               |> hd
    end
  end
end
