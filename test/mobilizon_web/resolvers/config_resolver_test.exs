defmodule MobilizonWeb.Resolvers.ConfigResolverTest do
  alias MobilizonWeb.AbsintheHelpers
  use MobilizonWeb.ConnCase
  use Bamboo.Test

  describe "Resolver: Get config" do
    test "get_config/3 returns the instance config", context do
      query = """
      {
        config {
            name,
            registrationsOpen
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "config"))

      assert json_response(res, 200)["data"]["config"]["name"] == "Test instance"
      assert json_response(res, 200)["data"]["config"]["registrationsOpen"] == true
    end
  end
end
