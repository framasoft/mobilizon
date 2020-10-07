defmodule Mobilizon.GraphQL.Resolvers.StatisticsTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "statistics resolver" do
    @statistics_query """
    query {
      statistics {
        numberOfUsers
        numberOfEvents
        numberOfLocalEvents
        numberOfComments
        numberOfLocalComments
        numberOfGroups
        numberOfLocalGroups
        numberOfInstanceFollowings
        numberOfInstanceFollowers
      }
    }
    """

    test "get statistics", %{conn: conn} do
      Cachex.clear(:statistics)
      insert(:event)
      insert(:comment)
      insert(:group)
      actor = insert(:actor, user: nil, domain: "toto.tld")
      insert(:event, organizer_actor: actor, local: false)

      res = AbsintheHelpers.graphql_query(conn, query: @statistics_query)

      assert res["data"]["statistics"]["numberOfUsers"] == 6
      assert res["data"]["statistics"]["numberOfLocalEvents"] == 2
      assert res["data"]["statistics"]["numberOfEvents"] == 3
      assert res["data"]["statistics"]["numberOfLocalComments"] == 1
      assert res["data"]["statistics"]["numberOfLocalGroups"] == 1

      insert(:event)
      # We keep the value in cache
      assert res["data"]["statistics"]["numberOfLocalEvents"] == 2
    end
  end
end
