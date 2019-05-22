defmodule MobilizonWeb.Resolvers.PictureResolverTest do
  alias MobilizonWeb.AbsintheHelpers
  use MobilizonWeb.ConnCase
  use Bamboo.Test
  alias Mobilizon.Media.Picture
  import Mobilizon.Factory

  setup %{conn: conn} do
    user = insert(:user)

    {:ok, conn: conn, user: user}
  end

  describe "Resolver: Get picture" do
    test "picture/3 returns the information on a picture", context do
      %Picture{id: id} = picture = insert(:picture)

      query = """
      {
        picture(id: "#{id}") {
            name,
            alt,
            url
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "picture"))

      assert json_response(res, 200)["data"]["picture"]["name"] == picture.file.name

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
    test "upload_picture/3 uploads a new picture", %{conn: conn, user: user} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadPicture(
              name: "#{picture.name}",
              alt: "#{picture.alt}",
              file: "#{picture.file}"
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
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post(
          "/api",
          map
        )

      assert json_response(res, 200)["data"]["uploadPicture"]["name"] == picture.name
      assert json_response(res, 200)["data"]["uploadPicture"]["url"]
    end

    test "upload_picture/3 forbids uploading if no auth", %{conn: conn} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadPicture(
              name: "#{picture.name}",
              alt: "#{picture.alt}",
              file: "#{picture.file}"
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
