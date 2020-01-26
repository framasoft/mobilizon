defmodule Mobilizon.GraphQL.Resolvers.TagTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "Tag Resolver" do
    test "list_tags/3 returns the list of tags", context do
      tag1 = insert(:tag)
      tag2 = insert(:tag)
      tag3 = insert(:tag)
      insert(:tag_relation, tag: tag1, link: tag2)
      insert(:tag_relation, tag: tag3, link: tag1)

      query = """
      {
        tags {
          id,
          slug,
          title,
          related {
            id,
            title,
            slug
          }
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "tags"))

      tags = json_response(res, 200)["data"]["tags"]
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
  end
end
