defmodule Mobilizon.GraphQL.Resolvers.PictureTest do
  use Mobilizon.Web.ConnCase
  use Bamboo.Test

  import Mobilizon.Factory

  alias Mobilizon.Media.Picture

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Endpoint

  @default_picture_details %{name: "my pic", alt: "represents something", file: "picture.png"}
  @default_picture_path "test/fixtures/picture.png"

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

  describe "Resolver: Get actor media size" do
    @actor_media_size_query """
    query LoggedPerson {
      loggedPerson {
        id
        mediaSize
      }
    }
    """

    test "with own actor", %{conn: conn} do
      user = insert(:user)
      insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @actor_media_size_query)

      assert res["data"]["loggedPerson"]["mediaSize"] == 0

      res = upload_picture(conn, user)
      assert res["data"]["uploadPicture"]["size"] == 10_097

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @actor_media_size_query)

      assert res["data"]["loggedPerson"]["mediaSize"] == 10_097

      res =
        upload_picture(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_picture_details, :file, "image.jpg")
        )

      assert res["data"]["uploadPicture"]["size"] == 13_227

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @actor_media_size_query)

      assert res["data"]["loggedPerson"]["mediaSize"] == 23_324
    end

    @list_actors_query """
    query ListPersons($preferredUsername: String) {
      persons(preferredUsername: $preferredUsername) {
        total,
        elements {
          id
          mediaSize
        }
      }
    }
    """

    test "as a moderator", %{conn: conn} do
      moderator = insert(:user, role: :moderator)
      user = insert(:user)
      actor = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(moderator)
        |> AbsintheHelpers.graphql_query(
          query: @list_actors_query,
          variables: %{preferredUsername: actor.preferred_username}
        )

      assert is_nil(res["errors"])
      assert hd(res["data"]["persons"]["elements"])["mediaSize"] == 0

      upload_picture(conn, user)

      res =
        conn
        |> auth_conn(moderator)
        |> AbsintheHelpers.graphql_query(
          query: @list_actors_query,
          variables: %{preferredUsername: actor.preferred_username}
        )

      assert is_nil(res["errors"])
      assert hd(res["data"]["persons"]["elements"])["mediaSize"] == 10_097
    end

    @event_organizer_media_query """
    query Event($uuid: UUID!) {
      event(uuid: $uuid) {
        id
        organizerActor {
          id
          mediaSize
        }
      }
    }
    """

    test "as a different user", %{conn: conn} do
      user = insert(:user)
      event = insert(:event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @event_organizer_media_query,
          variables: %{uuid: event.uuid}
        )

      assert hd(res["errors"])["message"] == "unauthorized"
    end

    test "without being logged-in", %{conn: conn} do
      event = insert(:event)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @event_organizer_media_query,
          variables: %{uuid: event.uuid}
        )

      assert hd(res["errors"])["message"] == "unauthenticated"
    end
  end

  describe "Resolver: Get user media size" do
    @user_media_size_query """
    query LoggedUser {
      loggedUser {
        id
        mediaSize
      }
    }
    """

    @change_default_actor_mutation """
    mutation ChangeDefaultActor($preferredUsername: String!) {
      changeDefaultActor(preferredUsername: $preferredUsername) {
          defaultActor {
            id
            preferredUsername
          }
        }
      }
    """

    test "with own user", %{conn: conn} do
      user = insert(:user)
      insert(:actor, user: user)
      actor_2 = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert res["errors"] == nil
      assert res["data"]["loggedUser"]["mediaSize"] == 0

      res = upload_picture(conn, user)
      assert res["data"]["uploadPicture"]["size"] == 10_097

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert res["data"]["loggedUser"]["mediaSize"] == 10_097

      res =
        upload_picture(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_picture_details, :file, "image.jpg")
        )

      assert res["data"]["uploadPicture"]["size"] == 13_227

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert res["data"]["loggedUser"]["mediaSize"] == 23_324

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_default_actor_mutation,
          variables: %{preferredUsername: actor_2.preferred_username}
        )

      assert is_nil(res["errors"])

      res =
        upload_picture(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_picture_details, :file, "image.jpg")
        )

      assert res["data"]["uploadPicture"]["size"] == 13_227

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert res["data"]["loggedUser"]["mediaSize"] == 36_551
    end

    @list_users_query """
    query ListUsers($email: String) {
      users(email: $email) {
        total,
        elements {
          id
          mediaSize
        }
      }
    }
    """

    test "as a moderator", %{conn: conn} do
      moderator = insert(:user, role: :moderator)
      user = insert(:user)
      insert(:actor, user: user)

      res =
        conn
        |> auth_conn(moderator)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{email: user.email}
        )

      assert is_nil(res["errors"])
      assert hd(res["data"]["users"]["elements"])["mediaSize"] == 0

      res = upload_picture(conn, user)
      assert is_nil(res["errors"])
      assert res["data"]["uploadPicture"]["size"] == 10_097

      res =
        conn
        |> auth_conn(moderator)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{email: user.email}
        )

      assert is_nil(res["errors"])
      assert hd(res["data"]["users"]["elements"])["mediaSize"] == 10_097
    end

    test "without being logged-in", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert hd(res["errors"])["message"] == "You need to be logged-in to view current user"
    end
  end

  @spec upload_picture(Plug.Conn.t(), Mobilizon.Users.User.t(), String.t(), map()) :: map()
  defp upload_picture(
         conn,
         user,
         picture_path \\ @default_picture_path,
         picture_details \\ @default_picture_details
       ) do
    map = %{
      "query" => @upload_picture_mutation,
      "variables" => picture_details,
      picture_details.file => %Plug.Upload{
        path: picture_path,
        filename: picture_details.file
      }
    }

    conn
    |> auth_conn(user)
    |> put_req_header("content-type", "multipart/form-data")
    |> post(
      "/api",
      map
    )
    |> json_response(200)
  end
end
