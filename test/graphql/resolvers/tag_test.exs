defmodule Mobilizon.GraphQL.Resolvers.TagTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  describe "list_tags/3" do
    @tags_query """
    query Tags($filter: String) {
      tags(filter: $filter) {
        id
        related {
          id
          slug
          title
        }
        slug
        title
      }
    }
    """

    test "requires being logged-in", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @tags_query)

      assert res["errors"] == nil
    end

    test "returns the list of tags", %{conn: conn, user: user} do
      tag1 = insert(:tag)
      tag2 = insert(:tag)
      tag3 = insert(:tag)
      insert(:tag_relation, tag: tag1, link: tag2)
      insert(:tag_relation, tag: tag3, link: tag1)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @tags_query)

      assert res["errors"] == nil
      tags = res["data"]["tags"]
      assert tags |> length == 3

      assert tags
             |> Enum.filter(fn tag -> tag["slug"] == tag1.slug end)
             |> hd
             |> Map.get("related")
             |> Enum.map(fn tag -> tag["slug"] end)
             |> MapSet.new() ==
               [tag2, tag3]
               |> Enum.map(fn tag -> tag.slug end)
               |> MapSet.new()
    end

    test "returns tags for a filter", %{conn: conn, user: user} do
      tag1 = insert(:tag, title: "PineApple", slug: "pineapple")
      tag2 = insert(:tag, title: "sexy pineapple", slug: "sexy-pineapple")
      _tag3 = insert(:tag)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @tags_query, variables: %{filter: "apple"})

      assert res["errors"] == nil
      tags = res["data"]["tags"]
      assert tags |> length == 2
      assert [tag1.id, tag2.id] == tags |> Enum.map(&String.to_integer(&1["id"]))
    end
  end
end
