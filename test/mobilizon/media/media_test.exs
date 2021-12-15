defmodule Mobilizon.MediaTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Config, Medias}
  alias Mobilizon.Medias.Media

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

    test "get_media!/1 returns the media with given id" do
      media = insert(:media)
      assert Medias.get_media!(media.id).id == media.id
    end

    test "create_media/1 with valid data creates a media" do
      assert {:ok, %Media{} = media} =
               Medias.create_media(Map.put(@valid_attrs, :actor_id, insert(:actor).id))

      assert media.file.name == "something old"
    end
  end

  describe "delete_media/1" do
    setup do
      File.rm_rf!(Config.get!([Uploader.Local, :uploads]))
      File.mkdir(Config.get!([Uploader.Local, :uploads]))
      :ok
    end

    test "deletes the media" do
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

    test "doesn't delete the media if two media entities are using the same URL" do
      Config.put([Mobilizon.Web.Upload, :filters], [
        Mobilizon.Web.Upload.Filter.Dedupe
      ])

      media1 = insert(:media)
      media2 = insert(:media)

      assert media1.file.url == media2.file.url

      %URI{path: "/media/" <> path} = URI.parse(media1.file.url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      assert {:ok, %Media{}} = Medias.delete_media(media1)
      assert_raise Ecto.NoResultsError, fn -> Medias.get_media!(media1.id) end

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      Config.put([Mobilizon.Web.Upload, :filters], [])
    end

    test "doesn't delete the media if the same file is being used in a profile" do
      Config.put([Mobilizon.Web.Upload, :filters], [
        Mobilizon.Web.Upload.Filter.Dedupe
      ])

      actor = insert(:actor)
      media = insert(:media)

      assert media.file.url == actor.avatar.url

      %URI{path: "/media/" <> path} = URI.parse(media.file.url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      assert {:ok, %Media{}} = Medias.delete_media(media)
      assert_raise Ecto.NoResultsError, fn -> Medias.get_media!(media.id) end

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> path
             )

      Config.put([Mobilizon.Web.Upload, :filters], [])
    end
  end
end
