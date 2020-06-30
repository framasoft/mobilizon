defmodule Mobilizon.Service.Geospatial.AddokTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase

  import Mock

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Config
  alias Mobilizon.Service.Geospatial.Addok

  @http_options [
    follow_redirect: true,
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  setup do
    # Config.instance_user_agent/0 makes database calls so because of ownership connection
    # we need to define it like this instead of a constant
    # See https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
    {:ok,
     httpoison_headers: [
       {"User-Agent", Config.instance_user_agent()}
     ]}
  end

  @endpoint get_in(Application.get_env(:mobilizon, Addok), [:endpoint])
  @fake_endpoint "https://domain.tld"

  describe "search address" do
    test "produces a valid search address", %{httpoison_headers: httpoison_headers} do
      with_mock HTTPoison, get: fn _url, _headers, _options -> "{}" end do
        Addok.search("10 Rue Jangot")

        assert_called(
          HTTPoison.get(
            "#{@endpoint}/search/?q=10%20Rue%20Jangot&limit=10",
            httpoison_headers,
            @http_options
          )
        )
      end
    end

    test "produces a valid search address with options", %{httpoison_headers: httpoison_headers} do
      with_mock HTTPoison, get: fn _url, _headers, _options -> "{}" end do
        Addok.search("10 Rue Jangot",
          endpoint: @fake_endpoint,
          limit: 5,
          coords: %{lat: 49, lon: 12}
        )

        assert_called(
          HTTPoison.get(
            "#{@fake_endpoint}/search/?q=10%20Rue%20Jangot&limit=5&lat=49&lon=12",
            httpoison_headers,
            @http_options
          )
        )
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/addok/search" do
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
    end

    test "returns a valid address from reverse geocode" do
      use_cassette "geospatial/addok/geocode" do
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
end
