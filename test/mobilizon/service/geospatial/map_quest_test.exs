defmodule Mobilizon.Service.Geospatial.MapQuestTest do
  use Mobilizon.DataCase, async: false
  alias Mobilizon.Service.Geospatial.MapQuest
  alias Mobilizon.Addresses.Address

  import Mock
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "search address" do
    test "without API Key triggers an error" do
      assert_raise ArgumentError, "API Key required to use MapQuest", fn ->
        MapQuest.search("10 Rue Jangot")
      end
    end

    test "produces a valid search address with options" do
      with_mock HTTPoison,
        get: fn _url ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"info\": {\"statuscode\": 0}, \"results\": []}"
           }}
        end do
        MapQuest.search("10 Rue Jangot",
          limit: 5,
          lang: "fr",
          api_key: "toto"
        )

        assert_called(
          HTTPoison.get(
            "https://open.mapquestapi.com/geocoding/v1/address?key=toto&location=10%20Rue%20Jangot&maxResults=5"
          )
        )
      end
    end

    test "triggers an error with an invalid API Key" do
      assert_raise ArgumentError, "The AppKey submitted with this request is invalid.", fn ->
        MapQuest.search("10 rue Jangot", api_key: "secret_key")
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/map_quest/search" do
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
    end

    test "returns a valid address from reverse geocode" do
      use_cassette "geospatial/map_quest/geocode" do
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
end
