defmodule Mobilizon.Service.Geospatial.GoogleMapsTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase

  import Mock

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.GoogleMaps

  @http_options [
    follow_redirect: true,
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  describe "search address" do
    test "without API Key triggers an error" do
      assert_raise ArgumentError, "API Key required to use Google Maps", fn ->
        GoogleMaps.search("10 Rue Jangot")
      end
    end

    test "produces a valid search address with options" do
      with_mock HTTPoison,
        get: fn _url, _headers, _options ->
          {:ok,
           %HTTPoison.Response{status_code: 200, body: "{\"status\": \"OK\", \"results\": []}"}}
        end do
        GoogleMaps.search("10 Rue Jangot",
          limit: 5,
          lang: "fr",
          api_key: "toto"
        )

        assert_called(
          HTTPoison.get(
            "https://maps.googleapis.com/maps/api/geocode/json?limit=5&key=toto&language=fr&address=10%20Rue%20Jangot",
            [],
            @http_options
          )
        )
      end
    end

    test "triggers an error with an invalid API Key" do
      assert_raise ArgumentError, "The provided API key is invalid.", fn ->
        GoogleMaps.search("10 rue Jangot", api_key: "secret_key")
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/google_maps/search" do
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
    end

    test "returns a valid address from reverse geocode" do
      use_cassette "geospatial/google_maps/geocode" do
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
end
