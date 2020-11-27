defmodule Mix.Tasks.Mobilizon.Media.CleanUnconfirmedUsersTest do
  use Mobilizon.DataCase
  import Mock
  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Users.Clean
  alias Mobilizon.Service.CleanUnconfirmedUsers

  Mix.shell(Mix.Shell.Process)

  describe "with default options" do
    test "nothing returned" do
      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, []} end do
        Clean.run([])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No users were deleted"
      end
    end

    test "users returned" do
      actor1 = insert(:actor)
      user1 = insert(:user, actors: [actor1])
      actor2 = insert(:actor)
      user2 = insert(:user, actors: [actor2])

      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, [user1, user2]} end do
        Clean.run([])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 users have been deleted"
      end
    end
  end

  describe "with dry-run option" do
    test "with nothing returned" do
      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: true, grace_period: 48] -> {:ok, []} end do
        Clean.run(["--dry-run"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No users would have been deleted"
      end
    end

    test "with users returned" do
      actor1 = insert(:actor)
      user1 = insert(:user, actors: [actor1])
      actor2 = insert(:actor)
      user2 = insert(:user, actors: [actor2])

      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: true, grace_period: 48] -> {:ok, [user1, user2]} end do
        Clean.run(["--dry-run"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "List of users that would have been deleted"
        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{user1.id}, Email: #{user1.email}, Profile: @#{actor1.preferred_username}"

        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{user2.id}, Email: #{user2.email}, Profile: @#{actor2.preferred_username}"

        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 users would have been deleted"
      end
    end
  end

  describe "with verbose option" do
    test "with nothing returned" do
      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, []} end do
        Clean.run(["--verbose"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No users were deleted"
      end
    end

    test "with users returned" do
      actor1 = insert(:actor)
      user1 = insert(:user, actors: [actor1])
      actor2 = insert(:actor)
      user2 = insert(:user, actors: [actor2])

      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 48] -> {:ok, [user1, user2]} end do
        Clean.run(["--verbose"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "List of users that have been deleted"
        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{user1.id}, Email: #{user1.email}, Profile: @#{actor1.preferred_username}"

        assert_received {:mix_shell, :info, [output_received]}

        assert output_received ==
                 "ID: #{user2.id}, Email: #{user2.email}, Profile: @#{actor2.preferred_username}"

        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "2 users have been deleted"
      end
    end
  end

  describe "with days option" do
    test "with nothing returned" do
      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 120] -> {:ok, []} end do
        Clean.run(["--days", "5"])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == "No users were deleted"
      end
    end
  end

  describe "returns an error" do
    test "for some reason" do
      with_mock CleanUnconfirmedUsers,
        clean: fn [dry_run: false, grace_period: 48] -> {:error, "Some error"} end do
        Clean.run([])
        assert_received {:mix_shell, :error, [output_received]}
        assert output_received == "Error while cleaning unconfirmed users"
      end
    end
  end
end
