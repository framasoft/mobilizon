defmodule Mobilizon.Service.CleanOrphanMediaTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media
  alias Mobilizon.Service.CleanOrphanMedia

  describe "clean orphan media" do
    test "with default values" do
      {:ok, old, _} = DateTime.from_iso8601("2020-11-20T17:35:23+01:00")
      %Media{id: media_id} = insert(:media, inserted_at: old)
      %Media{id: media_2_id} = insert(:media)

      refute is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))

      assert {:ok, [found_media]} = CleanOrphanMedia.clean()
      assert found_media.id == media_id

      assert is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))
    end

    test "as dry-run" do
      {:ok, old, _} = DateTime.from_iso8601("2020-11-20T17:35:23+01:00")
      %Media{id: media_id} = insert(:media, inserted_at: old)
      %Media{id: media_2_id} = insert(:media)

      refute is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))

      assert {:ok, [found_media]} = CleanOrphanMedia.clean(dry_run: true)
      assert found_media.id == media_id

      refute is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))
    end

    test "with custom grace period" do
      date = DateTime.utc_now() |> DateTime.add(24 * -3600)
      %Media{id: media_id} = insert(:media, inserted_at: date)
      %Media{id: media_2_id} = insert(:media)

      refute is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))

      assert {:ok, [found_media]} = CleanOrphanMedia.clean(grace_period: 12)
      assert found_media.id == media_id

      assert is_nil(Medias.get_media(media_id))
      refute is_nil(Medias.get_media(media_2_id))
    end
  end
end
