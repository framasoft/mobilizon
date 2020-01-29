defmodule Mobilizon.Service.Geospatial.NominatimTest do
  use Mobilizon.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Config
  alias Mobilizon.Service.Geospatial.Nominatim

  setup do
    # Config.instance_user_agent/0 makes database calls so because of ownership connection
    # we need to define it like this instead of a constant
    # See https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
    {:ok,
     httpoison_headers: [
       {"User-Agent", Config.instance_user_agent()}
     ]}
  end

  describe "search address" do
    test "produces a valid search address with options", %{httpoison_headers: httpoison_headers} do
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
            httpoison_headers
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
