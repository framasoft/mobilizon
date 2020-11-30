defmodule Mobilizon.GraphQL.Resolvers.MediaTest do
  use Mobilizon.Web.ConnCase
  use Bamboo.Test

  import Mobilizon.Factory

  alias Mobilizon.Medias.Media

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Endpoint

  @default_media_details %{name: "my pic", alt: "represents something", file: "picture.png"}
  @default_media_path "test/fixtures/picture.png"

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, user: user, actor: actor}
  end

  @media_query """
  query Media($id: ID!) {
    media(id: $id) {
      id
      name,
      alt,
      url,
      content_type,
      size
    }
  }
  """

  @upload_media_mutation """
  mutation UploadMedia($name: String!, $alt: String, $file: Upload!) {
    uploadMedia(
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

  describe "Resolver: Get media" do
    test "media/3 returns the information on a media", %{conn: conn} do
      %Media{id: id} = media = insert(:media)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @media_query, variables: %{id: id})

      assert res["data"]["media"]["name"] == media.file.name

      assert res["data"]["media"]["content_type"] ==
               media.file.content_type

      assert res["data"]["media"]["size"] == 13_120

      assert res["data"]["media"]["url"] =~ Endpoint.url()
    end

    test "media/3 returns nothing on a non-existent media", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @media_query, variables: %{id: 3})

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end
  end

  describe "Resolver: Upload media" do
    test "upload_media/3 uploads a new media", %{conn: conn, user: user} do
      media = %{name: "my pic", alt: "represents something", file: "picture.png"}

      map = %{
        "query" => @upload_media_mutation,
        "variables" => media,
        media.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: media.file
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

      assert res["data"]["uploadMedia"]["name"] == media.name
      assert res["data"]["uploadMedia"]["content_type"] == "image/png"
      assert res["data"]["uploadMedia"]["size"] == 10_097
      assert res["data"]["uploadMedia"]["url"]
    end

    test "upload_media/3 forbids uploading if no auth", %{conn: conn} do
      media = %{name: "my pic", alt: "represents something", file: "picture.png"}

      map = %{
        "query" => @upload_media_mutation,
        "variables" => media,
        media.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: media.file
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

  describe "Resolver: Remove media" do
    @remove_media_mutation """
    mutation RemoveMedia($id: ID!) {
      removeMedia(id: $id) {
        id
      }
    }
    """

    test "Removes a previously uploaded media", %{conn: conn, user: user, actor: actor} do
      %Media{id: media_id} = insert(:media, actor: actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @remove_media_mutation,
          variables: %{id: media_id}
        )

      assert is_nil(res["errors"])
      assert res["data"]["removeMedia"]["id"] == to_string(media_id)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @media_query, variables: %{id: media_id})

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end

    test "Removes nothing if media is not found", %{conn: conn, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @remove_media_mutation,
          variables: %{id: 400}
        )

      assert hd(res["errors"])["message"] == "Resource not found"
      assert hd(res["errors"])["status_code"] == 404
    end

    test "Removes nothing if media if not logged-in", %{conn: conn, actor: actor} do
      %Media{id: media_id} = insert(:media, actor: actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @remove_media_mutation,
          variables: %{id: media_id}
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

      res = upload_media(conn, user)
      assert res["data"]["uploadMedia"]["size"] == 10_097

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @actor_media_size_query)

      assert res["data"]["loggedPerson"]["mediaSize"] == 10_097

      res =
        upload_media(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_media_details, :file, "image.jpg")
        )

      assert res["data"]["uploadMedia"]["size"] == 13_227

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

      upload_media(conn, user)

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

      res = upload_media(conn, user)
      assert res["data"]["uploadMedia"]["size"] == 10_097

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_media_size_query)

      assert res["data"]["loggedUser"]["mediaSize"] == 10_097

      res =
        upload_media(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_media_details, :file, "image.jpg")
        )

      assert res["data"]["uploadMedia"]["size"] == 13_227

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
        upload_media(
          conn,
          user,
          "test/fixtures/image.jpg",
          Map.put(@default_media_details, :file, "image.jpg")
        )

      assert res["data"]["uploadMedia"]["size"] == 13_227

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

      res = upload_media(conn, user)
      assert is_nil(res["errors"])
      assert res["data"]["uploadMedia"]["size"] == 10_097

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

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end
  end

  @spec upload_media(Plug.Conn.t(), Mobilizon.Users.User.t(), String.t(), map()) :: map()
  defp upload_media(
         conn,
         user,
         media_path \\ @default_media_path,
         media_details \\ @default_media_details
       ) do
    map = %{
      "query" => @upload_media_mutation,
      "variables" => media_details,
      media_details.file => %Plug.Upload{
        path: media_path,
        filename: media_details.file
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
