defmodule Mobilizon.GraphQL.Resolvers.ConfigTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "Resolver: Get config" do
    test "get_config/3 returns the instance config", context do
      Cachex.clear("full_config")
      Mobilizon.Config.clear_config_cache()
      Config.put([:instance, :name], "Test instance")
      Config.put([:instance, :registrations_open], true)
      Config.put([:instance, :demo], false)
      Config.put([:instance, :duration_of_long_event], 0)

      Config.put(
        [:instance, :description],
        "Change this to a proper description of your instance"
      )

      Config.put([:instance, :federating], true)

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

    test "get_config/3 returns the instance config default", context do
      Cachex.clear("full_config")
      Mobilizon.Config.clear_config_cache()
      Config.put([:instance, :name], "Test instance")
      Config.put([:instance, :registrations_open], true)
      Config.put([:instance, :demo], false)
      Config.put([:instance, :duration_of_long_event], 0)

      Config.put(
        [:instance, :description],
        "Change this to a proper description of your instance"
      )

      Config.put([:instance, :federating], true)

      query = """
      {
        config {
            name,
            registrationsOpen,
            registrations_allowlist,
            contact,
            demo_mode,
            long_events,
            description,
            long_description,
            slogan,
            languages,
            timezones,
            rules,
            version,
            federating
        }
      }
      """

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(query: query)

      assert res["data"]["config"]["name"] == "Test instance"
      assert res["data"]["config"]["registrationsOpen"] == true
      assert res["data"]["config"]["registrations_allowlist"] == false
      assert res["data"]["config"]["contact"] == nil
      assert res["data"]["config"]["demo_mode"] == false
      assert res["data"]["config"]["long_events"] == false

      assert res["data"]["config"]["description"] ==
               "Change this to a proper description of your instance"

      assert res["data"]["config"]["long_description"] == nil
      assert res["data"]["config"]["slogan"] == nil
      assert res["data"]["config"]["languages"] == []
      assert length(res["data"]["config"]["timezones"]) == 594
      assert res["data"]["config"]["rules"] == nil
      assert String.slice(res["data"]["config"]["version"], 0, 5) == "5.0.1"
      assert res["data"]["config"]["federating"] == true
    end

    test "get_config/3 returns the instance config changed", context do
      Cachex.clear("full_config")
      Mobilizon.Config.clear_config_cache()
      Config.put([:instance, :name], "My instance")
      Config.put([:instance, :registrations_open], false)
      Config.put([:instance, :demo], true)
      Config.put([:instance, :duration_of_long_event], 30)
      Config.put([:instance, :description], "My description")
      Config.put([:instance, :federating], false)

      query = """
      {
        config {
            name,
            registrationsOpen,
            demo_mode,
            long_events,
            description,
            federating
        }
      }
      """

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(query: query)

      assert res["data"]["config"]["name"] == "My instance"
      assert res["data"]["config"]["registrationsOpen"] == false
      assert res["data"]["config"]["demo_mode"] == true
      assert res["data"]["config"]["long_events"] == true
      assert res["data"]["config"]["description"] == "My description"
      assert res["data"]["config"]["federating"] == false
    end
  end
end
