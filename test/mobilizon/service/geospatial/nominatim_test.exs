defmodule Mobilizon.Service.Geospatial.NominatimTest do
  use Mobilizon.DataCase, async: false
  alias Mobilizon.Service.Geospatial.Nominatim
  alias Mobilizon.Addresses.Address

  import Mock
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "search address" do
    test "produces a valid search address with options" do
      with_mock HTTPoison,
        get: fn _url ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "[]"}}
        end do
        Nominatim.search("10 Rue Jangot",
          limit: 5,
          lang: "fr"
        )

        assert_called(
          HTTPoison.get(
            "https://nominatim.openstreetmap.org/search?format=jsonv2&q=10%20Rue%20Jangot&limit=5&accept-language=fr&addressdetails=1"
          )
        )
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/nominatim/search" do
        assert %Address{
                 locality: "Lyon",
                 description:
                   "10, Rue Jangot, La Guillotière, Lyon 7e Arrondissement, Lyon, Métropole de Lyon, Departemental constituency of Rhône, Auvergne-Rhône-Alpes, Metropolitan France, 69007, France",
                 region: "Auvergne-Rhône-Alpes",
                 country: "France",
                 postal_code: "69007",
                 street: "10 Rue Jangot",
                 geom: %Geo.Point{
                   coordinates: {4.8425657, 45.7517141},
                   properties: %{},
                   srid: 4326
                 },
                 origin_id: "osm:3078260611"
               } == Nominatim.search("10 rue Jangot") |> hd
      end
    end

    test "returns a valid address from reverse geocode" do
      use_cassette "geospatial/nominatim/geocode" do
        assert %Address{
                 locality: "Lyon",
                 description:
                   "10, Rue Jangot, La Guillotière, Lyon 7e Arrondissement, Lyon, Métropole de Lyon, Circonscription départementale du Rhône, Auvergne-Rhône-Alpes, France métropolitaine, 69007, France",
                 region: "Auvergne-Rhône-Alpes",
                 country: "France",
                 postal_code: "69007",
                 street: "10 Rue Jangot",
                 geom: %Geo.Point{
                   coordinates: {4.8425657, 45.7517141},
                   properties: %{},
                   srid: 4326
                 },
                 origin_id: "osm:3078260611"
               } ==
                 Nominatim.geocode(4.842569, 45.751718)
                 |> hd
      end
    end
  end
end
