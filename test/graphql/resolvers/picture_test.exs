defmodule Mobilizon.GraphQL.Resolvers.PictureTest do
  use MobilizonWeb.ConnCase
  use Bamboo.Test

  import Mobilizon.Factory

  alias Mobilizon.Media.Picture

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, user: user, actor: actor}
  end

  describe "Resolver: Get picture" do
    test "picture/3 returns the information on a picture", context do
      %Picture{id: id} = picture = insert(:picture)

      query = """
      {
        picture(id: "#{id}") {
            name,
            alt,
            url,
            content_type,
            size
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "picture"))

      assert json_response(res, 200)["data"]["picture"]["name"] == picture.file.name

      assert json_response(res, 200)["data"]["picture"]["content_type"] ==
               picture.file.content_type

      assert json_response(res, 200)["data"]["picture"]["size"] == 13_120

      assert json_response(res, 200)["data"]["picture"]["url"] =~
               MobilizonWeb.Endpoint.url()
    end

    test "picture/3 returns nothing on a non-existent picture", context do
      query = """
      {
        picture(id: "3") {
            name,
            alt,
            url
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "picture"))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Picture with ID 3 was not found"
    end
  end

  describe "Resolver: Upload picture" do
    test "upload_picture/3 uploads a new picture", %{conn: conn, user: user, actor: actor} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadPicture(
              name: "#{picture.name}",
              alt: "#{picture.alt}",
              file: "#{picture.file}",
              actor_id: #{actor.id}
            ) {
                url,
                name,
                content_type,
                size
              }
        }
      """

      map = %{
        "query" => mutation,
        picture.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: picture.file
        }
      }

      res =
        conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post(
          "/api",
          map
        )

      assert json_response(res, 200)["data"]["uploadPicture"]["name"] == picture.name
      assert json_response(res, 200)["data"]["uploadPicture"]["content_type"] == "image/png"
      assert json_response(res, 200)["data"]["uploadPicture"]["size"] == 10_097
      assert json_response(res, 200)["data"]["uploadPicture"]["url"]
    end

    test "upload_picture/3 forbids uploading if no auth", %{conn: conn, actor: actor} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadPicture(
              name: "#{picture.name}",
              alt: "#{picture.alt}",
              file: "#{picture.file}",
              actor_id: #{actor.id}
            ) {
                url,
                name
              }
        }
      """

      map = %{
        "query" => mutation,
        picture.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: picture.file
        }
      }

      res =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post(
          "/api",
          map
        )

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to login to upload a picture"
    end
  end
end
