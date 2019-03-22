defmodule MobilizonWeb.Resolvers.AddressResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  describe "Address Resolver" do
    test "search/3 search for addresses", %{conn: conn} do
      address = insert(:address, description: "10 rue Jangot, Lyon")

      query = """
        {
          searchAddress(query: "10 Rue Jangot") {
            street,
            description,
            geom
          }
        }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "address"))

      json_response(res, 200)["data"]["searchAddress"]
      |> Enum.each(fn addr -> assert Map.get(addr, "description") == address.description end)
    end

    test "geocode/3 reverse geocodes coordinates", %{conn: conn} do
      address =
        insert(:address,
          description: "10 rue Jangot, Lyon"
        )

      query = """
        {
          reverseGeocode(longitude: -23.01, latitude: 30.01) {
            description,
            geom
          }
        }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "address"))

      assert json_response(res, 200)["data"]["reverseGeocode"] == []

      query = """
        {
          reverseGeocode(longitude: 45.75, latitude: 4.85) {
            description,
            geom
          }
        }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "address"))

      assert json_response(res, 200)["data"]["reverseGeocode"] |> hd |> Map.get("description") ==
               address.description
    end
  end
end
