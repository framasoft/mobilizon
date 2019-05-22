defmodule Mobilizon.MediaTest do
  use Mobilizon.DataCase

  alias Mobilizon.Media
  import Mobilizon.Factory

  describe "media" do
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
      assert Media.get_picture!(picture.id) == picture
    end

    test "create_picture/1 with valid data creates a picture" do
      assert {:ok, %Picture{} = picture} = Media.create_picture(@valid_attrs)
      assert picture.file.name == "something old"
    end

    test "update_picture/2 with valid data updates the picture" do
      picture = insert(:picture)
      assert {:ok, %Picture{} = picture} = Media.update_picture(picture, @update_attrs)
      assert picture.file.name == "something new"
    end

    test "delete_picture/1 deletes the picture" do
      picture = insert(:picture)
      assert {:ok, %Picture{}} = Media.delete_picture(picture)
      assert_raise Ecto.NoResultsError, fn -> Media.get_picture!(picture.id) end
    end

    test "change_picture/1 returns a picture changeset" do
      picture = insert(:picture)
      assert %Ecto.Changeset{} = Media.change_picture(picture)
    end
  end
end
