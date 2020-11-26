defmodule Mix.Tasks.Mobilizon.User.CleanUnconfirmedUsersTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Service.CleanUnconfirmedUsers
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  describe "clean unconfirmed users" do
    test "with default values" do
      {:ok, old, _} = DateTime.from_iso8601("2020-11-20T17:35:23+01:00")
      %User{id: user_id} = insert(:user, confirmation_sent_at: old, confirmed_at: nil)
      %User{id: user_2_id} = insert(:user)

      refute is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))

      assert {:ok, [found_user]} = CleanUnconfirmedUsers.clean()
      assert found_user.id == user_id

      assert is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))
    end

    test "as dry-run" do
      {:ok, old, _} = DateTime.from_iso8601("2020-11-20T17:35:23+01:00")
      %User{id: user_id} = insert(:user, confirmation_sent_at: old, confirmed_at: nil)
      %User{id: user_2_id} = insert(:user)

      refute is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))

      assert {:ok, [found_user]} = CleanUnconfirmedUsers.clean(dry_run: true)
      assert found_user.id == user_id

      refute is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))
    end

    test "with custom grace period" do
      date = DateTime.utc_now() |> DateTime.add(24 * -3600)
      %User{id: user_id} = insert(:user, confirmation_sent_at: date, confirmed_at: nil)
      %User{id: user_2_id} = insert(:user)

      refute is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))

      assert {:ok, [found_user]} = CleanUnconfirmedUsers.clean(grace_period: 12)
      assert found_user.id == user_id

      assert is_nil(Users.get_user(user_id))
      refute is_nil(Users.get_user(user_2_id))
    end
  end
end
