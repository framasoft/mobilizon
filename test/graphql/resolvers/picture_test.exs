defmodule Mobilizon.GraphQL.Resolvers.PictureTest do
  use Mobilizon.Web.ConnCase
  use Bamboo.Test

  import Mobilizon.Factory

  alias Mobilizon.Media.Picture

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Endpoint

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, user: user, actor: actor}
  end

  @picture_query """
  query Picture($id: ID!) {
    picture(id: $id) {
      id
      name,
      alt,
      url,
      content_type,
      size
    }
  }
  """

  describe "Resolver: Get picture" do
    test "picture/3 returns the information on a picture", %{conn: conn} do
      %Picture{id: id} = picture = insert(:picture)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @picture_query, variables: %{id: id})

      assert res["data"]["picture"]["name"] == picture.file.name

      assert res["data"]["picture"]["content_type"] ==
               picture.file.content_type

      assert res["data"]["picture"]["size"] == 13_120

      assert res["data"]["picture"]["url"] =~ Endpoint.url()
    end

    test "picture/3 returns nothing on a non-existent picture", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @picture_query, variables: %{id: 3})

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end
  end

  describe "Resolver: Upload picture" do
    @upload_picture_mutation """
    mutation UploadPicture($name: String!, $alt: String, $file: Upload!) {
      uploadPicture(
        name: $name
        alt: $alt
        file: $file
      ) {
          url
          name
          content_type
          size
      }
    }
    """

    test "upload_picture/3 uploads a new picture", %{conn: conn, user: user} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      map = %{
        "query" => @upload_picture_mutation,
        "variables" => picture,
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
        |> json_response(200)

      assert res["data"]["uploadPicture"]["name"] == picture.name
      assert res["data"]["uploadPicture"]["content_type"] == "image/png"
      assert res["data"]["uploadPicture"]["size"] == 10_097
      assert res["data"]["uploadPicture"]["url"]
    end

    test "upload_picture/3 forbids uploading if no auth", %{conn: conn} do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      map = %{
        "query" => @upload_picture_mutation,
        "variables" => picture,
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
        |> json_response(200)

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end
  end

  describe "Resolver: Remove picture" do
    @remove_picture_mutation """
    mutation RemovePicture($id: ID!) {
      removePicture(id: $id) {
        id
      }
    }
    """

    test "Removes a previously uploaded picture", %{conn: conn, user: user, actor: actor} do
      %Picture{id: picture_id} = insert(:picture, actor: actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @remove_picture_mutation,
          variables: %{id: picture_id}
        )

      assert is_nil(res["errors"])
      assert res["data"]["removePicture"]["id"] == to_string(picture_id)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @picture_query, variables: %{id: picture_id})

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end

    test "Removes nothing if picture is not found", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @remove_picture_mutation,
          variables: %{id: 400}
        )

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end

    test "Removes nothing if picture if not logged-in", %{conn: conn, actor: actor} do
      %Picture{id: picture_id} = insert(:picture, actor: actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @remove_picture_mutation,
          variables: %{id: picture_id}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
      assert hd(res["errors"])["status_code"] == 401
    end
  end
end
