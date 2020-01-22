defmodule Mobilizon.Service.Geospatial.NominatimTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase, async: false

  import Mock

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Nominatim
  alias Mobilizon.Config

  @httpoison_headers [
    {"User-Agent",
     "#{Config.instance_name()} #{Config.instance_hostname()} - Mobilizon #{
       Mix.Project.config()[:version]
     }"}
  ]

  describe "search address" do
    test "produces a valid search address with options" do
      with_mock HTTPoison,
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "[]"}}
        end do
        Nominatim.search("10 Rue Jangot",
          limit: 5,
          lang: "fr"
        )

        assert_called(
          HTTPoison.get(
            "https://nominatim.openstreetmap.org/search?format=geocodejson&q=10%20Rue%20Jangot&limit=5&accept-language=fr&addressdetails=1&namedetails=1",
            @httpoison_headers
          )
        )
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/nominatim/search" do
        assert [
                 %Address{
                   locality: "Lyon",
                   description: "10 Rue Jangot",
                   region: "Auvergne-Rhône-Alpes",
                   country: "France",
                   postal_code: "69007",
                   street: "10 Rue Jangot",
                   geom: %Geo.Point{
                     coordinates: {4.8425657, 45.7517141},
                     properties: %{},
                     srid: 4326
                   },
                   origin_id: "nominatim:3078260611",
                   type: "house"
                 }
               ] == Nominatim.search("10 rue Jangot")
      end
    end

    test "returns a valid address from reverse geocode" do
      use_cassette "geospatial/nominatim/geocode" do
        assert [
                 %Address{
                   locality: "Lyon",
                   description: "10 Rue Jangot",
                   region: "Auvergne-Rhône-Alpes",
                   country: "France",
                   postal_code: "69007",
                   street: "10 Rue Jangot",
                   geom: %Geo.Point{
                     coordinates: {4.8425657, 45.7517141},
                     properties: %{},
                     srid: 4326
                   },
                   origin_id: "nominatim:3078260611",
                   type: "house"
                 }
               ] ==
                 Nominatim.geocode(4.842569, 45.751718)
      end
    end
  end
end
