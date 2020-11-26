defmodule Mix.Tasks.Mobilizon.Media.CleanOrphanTest do
  use Mobilizon.DataCase
  import Mock
  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Media.CleanOrphan
  alias Mobilizon.Service.CleanOrphanMedia

  Mix.shell(Mix.Shell.Process)

  describe "with default options" do
    test "nothing returned" do
      with_mock CleanOrphanMedia, clean: fn [dry_run: false, grace_period: 48] -> {:ok, []} end do
        CleanOrphan.run([])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No files were deleted"
      end
    end

    test "media returned" do
      media1 = insert(:media)
      media2 = insert(:media)

      with_mock CleanOrphanMedia,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, [media1, media2]} end do
        CleanOrphan.run([])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 files have been deleted"
      end
    end
  end

  describe "with dry-run option" do
    test "with nothing returned" do
      with_mock CleanOrphanMedia,
        clean: fn [dry_run: true, grace_period: 48] -> {:ok, []} end do
        CleanOrphan.run(["--dry-run"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No files would have been deleted"
      end
    end

    test "with media returned" do
      media1 = insert(:media)
      media2 = insert(:media)

      with_mock CleanOrphanMedia,
        clean: fn [dry_run: true, grace_period: 48] -> {:ok, [media1, media2]} end do
        CleanOrphan.run(["--dry-run"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "List of files that would have been deleted"
        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{media1.id}, Actor: #{media1.actor_id}, URL: #{media1.file.url}"

        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{media2.id}, Actor: #{media2.actor_id}, URL: #{media2.file.url}"

        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 files would have been deleted"
      end
    end
  end

  describe "with verbose option" do
    test "with nothing returned" do
      with_mock CleanOrphanMedia,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, []} end do
        CleanOrphan.run(["--verbose"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No files were deleted"
      end
    end

    test "with media returned" do
      media1 = insert(:media)
      media2 = insert(:media)

      with_mock CleanOrphanMedia,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, [media1, media2]} end do
        CleanOrphan.run(["--verbose"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "List of files that have been deleted"
        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{media1.id}, Actor: #{media1.actor_id}, URL: #{media1.file.url}"

        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{media2.id}, Actor: #{media2.actor_id}, URL: #{media2.file.url}"

        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 files have been deleted"
      end
    end
  end

  describe "with days option" do
    test "with nothing returned" do
      with_mock CleanOrphanMedia,
        clean: fn [dry_run: false, grace_period: 120] -> {:ok, []} end do
        CleanOrphan.run(["--days", "5"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No files were deleted"
      end
    end
  end

  describe "returns an error" do
    test "for some reason" do
      with_mock CleanOrphanMedia,
        clean: fn [dry_run: false, grace_period: 48] -> {:error, "Some error"} end do
        CleanOrphan.run([])
        assert_received {:mix_shell, :error, [output_received]}
        assert output_received == "Error while cleaning orphan media files"
      end
    end
  end
end
