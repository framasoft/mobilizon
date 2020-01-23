defmodule Mix.Tasks.Mobilizon.UsersTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mix.Tasks.Mobilizon.Users.{New, Delete, Show, Modify}

  Mix.shell(Mix.Shell.Process)

  @email "test@email.tld"
  describe "create user" do
    test "create with no options" do
      New.run([@email])

      assert {:ok, %User{email: email, role: role, confirmed_at: confirmed_at}} =
               Users.get_user_by_email(@email)

      assert email == @email
      assert role == :user
      refute is_nil(confirmed_at)
    end

    test "create a moderator" do
      New.run([@email, "--moderator"])

      assert {:ok, %User{email: email, role: role}} = Users.get_user_by_email(@email)
      assert email == @email
      assert role == :moderator
    end

    test "create an administrator" do
      New.run([@email, "--admin"])

      assert {:ok, %User{email: email, role: role}} = Users.get_user_by_email(@email)
      assert email == @email
      assert role == :administrator
    end

    test "create with already used email" do
      insert(:user, email: @email)

      assert_raise Mix.Error, "User has not been created because of the above reason.", fn ->
        New.run([@email])
      end
    end
  end

  describe "delete user" do
    test "delete existing user" do
      insert(:user, email: @email)
      Delete.run([@email, "-y"])
      assert {:error, :user_not_found} == Users.get_user_by_email(@email)
    end

    test "delete non-existing user" do
      assert_raise Mix.Error, "Error: No such user", fn -> Delete.run([@email, "-y"]) end
    end
  end

  describe "show user" do
    test "show existing user" do
      %User{confirmed_at: confirmed_at, role: role} = user = insert(:user, email: @email)
      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)

      output =
        "Informations for the user #{@email}:\n  - Activated: #{confirmed_at}\n  - Role: #{role}\n  Identities (2):\n    - @#{
          actor1.preferred_username
        } / \n    - @#{actor2.preferred_username} / \n\n\n"

      Show.run([@email])
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == output
    end

    test "show non-existing user" do
      assert_raise Mix.Error, "Error: No such user", fn -> Show.run([@email]) end
    end
  end

  describe "modify user" do
    test "modify existing user without any changes" do
      insert(:user, email: @email)

      Modify.run([@email])
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == "No change has been made"
    end

    test "promote an user to moderator" do
      insert(:user, email: @email)

      Modify.run([@email, "--moderator"])
      assert {:ok, %User{role: role}} = Users.get_user_by_email(@email)
      assert role == :moderator
    end

    test "promote an user to administrator" do
      insert(:user, email: @email)

      Modify.run([@email, "--admin"])
      assert {:ok, %User{role: role}} = Users.get_user_by_email(@email)
      assert role == :administrator

      Modify.run([@email, "--user"])
      assert {:ok, %User{role: role}} = Users.get_user_by_email(@email)
      assert role == :user
    end

    test "disable and enable an user" do
      user = insert(:user, email: @email)

      Modify.run([@email, "--disable"])
      assert_received {:mix_shell, :info, [output_received]}

      assert output_received ==
               "An user has been modified with the following information:\n  - email: #{
                 user.email
               }\n  - Role: #{user.role}\n  - Activated: False\n"

      assert {:ok, %User{email: email, confirmed_at: confirmed_at}} =
               Users.get_user_by_email(@email)

      assert is_nil(confirmed_at)

      Modify.run([@email, "--enable"])
      assert_received {:mix_shell, :info, [output_received]}

      assert {:ok, %User{email: email, confirmed_at: confirmed_at}} =
               Users.get_user_by_email(@email)

      assert output_received ==
               "An user has been modified with the following information:\n  - email: #{
                 user.email
               }\n  - Role: #{user.role}\n  - Activated: #{confirmed_at}\n"

      refute is_nil(confirmed_at)

      Modify.run([@email, "--enable"])

      assert {:ok, %User{email: email, confirmed_at: confirmed_at}} =
               Users.get_user_by_email(@email)

      refute is_nil(confirmed_at)
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == "No change has been made"
    end

    test "enable and disable at the same time" do
      assert_raise Mix.Error,
                   "Can't use both --enabled and --disable options at the same time.",
                   fn ->
                     Modify.run([@email, "--disable", "--enable"])
                   end
    end
  end
end
