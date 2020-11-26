defmodule Mobilizon.MediaTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Config, Medias}

  alias Mobilizon.Web.Upload.Uploader

  describe "media" do
    setup [:ensure_local_uploader]
    alias Mobilizon.Medias.Media

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

    test "get_media!/1 returns the media with given id" do
      media = insert(:media)
      assert Medias.get_media!(media.id).id == media.id
    end

    test "create_media/1 with valid data creates a media" do
      assert {:ok, %Media{} = media} =
               Medias.create_media(Map.put(@valid_attrs, :actor_id, insert(:actor).id))

      assert media.file.name == "something old"
    end

    test "update_media/2 with valid data updates the media" do
      media = insert(:media)

      assert {:ok, %Media{} = media} =
               Medias.update_media(
                 media,
                 Map.put(@update_attrs, :actor_id, insert(:actor).id)
               )

      assert media.file.name == "something new"
    end

    test "delete_media/1 deletes the media" do
      media = insert(:media)

      %URI{path: "/media/" <> path} = URI.parse(media.file.url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      assert {:ok, %Media{}} = Medias.delete_media(media)
      assert_raise Ecto.NoResultsError, fn -> Medias.get_media!(media.id) end

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )
    end
  end
end
