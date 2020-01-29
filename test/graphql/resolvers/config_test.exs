defmodule Mobilizon.GraphQL.Resolvers.ConfigTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  use Bamboo.Test

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "Resolver: Get config" do
    test "get_config/3 returns the instance config", context do
      Cachex.clear("full_config")
      Mobilizon.Config.clear_config_cache()

      query = """
      {
        config {
            name,
            registrationsOpen
            anonymous {
              participation {
                allowed,
                validation {
                  email {
                    enabled,
                    confirmationRequired
                  }
                }
              },
              actor_id
            }
        }
      }
      """

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(query: query)

      assert res["data"]["config"]["name"] == "Test instance"
      assert res["data"]["config"]["registrationsOpen"] == true

      assert res["data"]["config"]["anonymous"]["participation"]["validation"]["email"]["enabled"] ==
               true

      assert res["data"]["config"]["anonymous"]["participation"]["validation"]["email"][
               "confirmationRequired"
             ] == true

      {:ok, %Actor{id: actor_id}} = Actors.get_or_create_internal_actor("anonymous")
      assert res["data"]["config"]["anonymous"]["actor_id"] == to_string(actor_id)
    end
  end
end
