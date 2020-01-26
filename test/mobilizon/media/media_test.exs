defmodule Mobilizon.MediaTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Config, Media}

  alias Mobilizon.Web.Upload.Uploader

  describe "media" do
    setup [:ensure_local_uploader]
    alias Mobilizon.Media.Picture

    @valid_attrs %{
      file: %{
        url: "https://something.tld/media/something",
        name: "something old"
      }
    }
    @update_attrs %{
      file: %{
        url: "https://something.tld/media/something_updated",
        name: "something new"
      }
    }

    test "get_picture!/1 returns the picture with given id" do
      picture = insert(:picture)
      assert Media.get_picture!(picture.id).id == picture.id
    end

    test "create_picture/1 with valid data creates a picture" do
      assert {:ok, %Picture{} = picture} =
               Media.create_picture(Map.put(@valid_attrs, :actor_id, insert(:actor).id))

      assert picture.file.name == "something old"
    end

    test "update_picture/2 with valid data updates the picture" do
      picture = insert(:picture)

      assert {:ok, %Picture{} = picture} =
               Media.update_picture(picture, Map.put(@update_attrs, :actor_id, insert(:actor).id))

      assert picture.file.name == "something new"
    end

    test "delete_picture/1 deletes the picture" do
      picture = insert(:picture)

      %URI{path: "/media/" <> path} = URI.parse(picture.file.url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      assert {:ok, %Picture{}} = Media.delete_picture(picture)
      assert_raise Ecto.NoResultsError, fn -> Media.get_picture!(picture.id) end

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )
    end
  end
end
