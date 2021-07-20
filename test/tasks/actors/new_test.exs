defmodule Mix.Tasks.Mobilizon.Actors.NewTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Actors.New

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  Mix.shell(Mix.Shell.Process)

  @email "me@some.where"
  describe "create profile" do
    setup do
      %User{} = user = insert(:user, email: @email)

      {:ok, user: user}
    end

    @preferred_username "toto"
    @name "Léo Pandaï"
    @converted_username "leo_pandai"

    test "create with no options" do
      New.run([])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "You need to provide at least --username or --display-name."
    end

    test "create when email isn't set" do
      New.run(["--display-name", @name])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "You need to provide an email for creating a new profile."
    end

    test "create when email doesn't exist" do
      New.run(["--email", "toto@somewhere.else", "--display-name", @name])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "No user with this email was found."
    end

    test "create with --display-name" do
      New.run(["--email", @email, "--display-name", @name])

      assert {:ok, %User{id: user_id}} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @converted_username,
               name: @name,
               domain: nil,
               user_id: ^user_id
             } = Actors.get_local_actor_by_name(@converted_username)
    end

    test "create with --username" do
      New.run(["--email", @email, "--username", @preferred_username])

      assert {:ok, %User{id: user_id}} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @preferred_username,
               name: @preferred_username,
               domain: nil,
               user_id: ^user_id
             } = Actors.get_local_actor_by_name(@preferred_username)
    end

    test "create with --username and --display-name" do
      New.run(["--email", @email, "--username", @preferred_username, "--display-name", @name])

      assert {:ok, %User{id: user_id}} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @preferred_username,
               name: @name,
               domain: nil,
               user_id: ^user_id
             } = Actors.get_local_actor_by_name(@preferred_username)
    end
  end

  describe "create group" do
    @already_existing_group "already_there"
    @already_existing_group_name "Already Thére"
    @profile_username "theo"

    setup do
      group = insert(:group, preferred_username: @already_existing_group)
      profile = insert(:actor, preferred_username: @profile_username)
      {:ok, group: group, profile: profile}
    end

    test "create with no options" do
      New.run(["--type", "group"])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "You need to provide at least --username or --display-name."
    end

    test "create when email isn't set" do
      New.run(["--type", "group", "--display-name", @name])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "You need to provide --group-admin with the username of the admin to create a group."
    end

    test "create when group admin doesn't exist" do
      New.run([
        "--type",
        "group",
        "--display-name",
        @name,
        "--group-admin",
        "some0ne_98"
      ])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "Profile with username some0ne_98 wasn't found"
    end

    test "create but the group already exists" do
      New.run([
        "--type",
        "group",
        "--display-name",
        @already_existing_group_name,
        "--group-admin",
        @profile_username
      ])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "[preferred_username: {\"This username is already taken.\", []}]"

      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "Error while creating group because of the above reason"
    end

    @group_name "My Awesome Group"
    @group_username "my_awesome_group"

    test "create group", %{profile: %Actor{id: admin_id}} do
      New.run([
        "--type",
        "group",
        "--display-name",
        @group_name,
        "--group-admin",
        @profile_username
      ])

      assert %Actor{name: @group_name, preferred_username: @group_username, id: group_id} =
               Actors.get_group_by_title(@group_username)

      assert Actors.is_administrator?(admin_id, group_id)
    end
  end
end
