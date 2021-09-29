defmodule Mobilizon.GraphQL.Resolvers.TagTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "Tag Resolver" do
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

    test "list_tags/3 returns the list of tags", %{conn: conn} do
      tag1 = insert(:tag)
      tag2 = insert(:tag)
      tag3 = insert(:tag)
      insert(:tag_relation, tag: tag1, link: tag2)
      insert(:tag_relation, tag: tag3, link: tag1)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @tags_query)

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

    test "list_tags/3 returns tags for a filter", %{conn: conn} do
      tag1 = insert(:tag, title: "PineApple", slug: "pineapple")
      tag2 = insert(:tag, title: "sexy pineapple", slug: "sexy-pineapple")
      _tag3 = insert(:tag)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @tags_query, variables: %{filter: "apple"})

      tags = res["data"]["tags"]
      assert tags |> length == 2
      assert [tag1.id, tag2.id] == tags |> Enum.map(&String.to_integer(&1["id"]))
    end
  end
end
