defmodule MobilizonWeb.Resolvers.CategoryResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  setup %{conn: conn} do
    {:ok, %Actor{} = actor} =
      Actors.register(%{email: "test@test.tld", password: "testest", username: "test"})

    {:ok, conn: conn, actor: actor}
  end

  describe "Category Resolver" do
    test "list_categories/3 returns the list of categories", context do
      insert(:category)
      insert(:category)

      query = """
      {
          categories {
              id,
              title,
              description,
              picture {
                  url,
              },
          }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "categories"))

      assert json_response(res, 200)["data"]["categories"] |> length == 2
    end

    # We can't test an upload…yet?
    # test "create_category/3 creates a category", %{conn: conn, actor: actor} do
    #   mutation = """
    #       mutation {
    #         createCategory(title: "my category", description: "my desc") {
    #             id,
    #             title,
    #             description,
    #         },
    #       }
    #   """

    #   res =
    #     conn
    #     |> auth_conn(actor.user)
    #     |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    #   assert json_response(res, 200)["data"]["createCategory"]["title"] == "my category"
    # end

    # test "create_category/3 doesn't create a category if the user isn't logged in", %{conn: conn, actor: actor} do
    #   mutation = """
    #       mutation {
    #         createCategory(title: "my category", description: "my desc") {
    #             id,
    #             title,
    #             description,
    #         },
    #       }
    #   """

    #   res =
    #     conn
    #     |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    #     assert hd(json_response(res, 200)["errors"])["message"] ==
    #     "You are not allowed to create a category if not connected"
    # end
  end
end
