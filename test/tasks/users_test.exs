defmodule Mix.Tasks.Mobilizon.UsersTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Users.{Delete, Modify, New, Show}

  alias Mobilizon.{Actors, Config, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  Mix.shell(Mix.Shell.Process)

  @email "test@email.tld"
  describe "create user" do
    test "create with no options" do
      New.run([@email])

      assert {:ok, %User{email: email, role: role, confirmed_at: confirmed_at, provider: nil}} =
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

      New.run([@email])
      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "[email: {\"This email is already used.\", [constraint: :unique, constraint_name: \"users_email_index\"]}]"

      assert_received {:mix_shell, :error, [message]}
      assert message =~ "User has not been created because of the above reason."
    end
  end

  describe "create user from external provider" do
    test "create user from ldap" do
      New.run([@email, "--provider", "ldap"])

      assert {:ok,
              %User{email: @email, password: nil, provider: "ldap", confirmed_at: %DateTime{}}} =
               Users.get_user_by_email(@email)

      assert_received {:mix_shell, :info, [message]}

      assert message =~
               "Warning: The ldap provider isn't currently configured as default authenticator."
    end

    test "create user from ldap when configured" do
      Config.put([Mobilizon.Service.Auth.Authenticator], Mobilizon.Service.Auth.LDAPAuthenticator)

      New.run([@email, "--provider", "ldap"])

      assert {:ok,
              %User{email: @email, password: nil, provider: "ldap", confirmed_at: %DateTime{}}} =
               Users.get_user_by_email(@email)

      assert_received {:mix_shell, :info, [message]}

      refute message =~
               "Warning: The ldap provider isn't currently configured as default authenticator."

      Config.put(
        [Mobilizon.Service.Auth.Authenticator],
        Mobilizon.Service.Auth.MobilizonAuthenticator
      )
    end

    test "can't set --provider at the same time than --password" do
      New.run([@email, "--provider", "ldap", "--password", "random"])

      assert {:ok,
              %User{email: @email, password: nil, provider: "ldap", confirmed_at: %DateTime{}}} =
               Users.get_user_by_email(@email)

      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "The --password and --provider options can't be specified at the same time."
    end
  end

  describe "create user and profile" do
    @preferred_username "toto"
    @name "Léo Pandaï"
    @converted_username "leo_pandai"

    test "create a profile with the user" do
      New.run([@email, "--profile-username", @preferred_username, "--profile-display-name", @name])

      assert {:ok,
              %User{
                email: email,
                role: role,
                confirmed_at: confirmed_at,
                id: user_id,
                default_actor_id: user_default_actor_id
              }} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @preferred_username,
               name: @name,
               domain: nil,
               user_id: ^user_id,
               id: actor_id
             } = Actors.get_local_actor_by_name(@preferred_username)

      assert user_default_actor_id == actor_id
      assert email == @email
      assert role == :user
      refute is_nil(confirmed_at)
    end

    test "create a profile from displayed name only" do
      New.run([@email, "--profile-display-name", @name])

      assert {:ok,
              %User{
                email: email,
                role: role,
                confirmed_at: confirmed_at,
                id: user_id,
                default_actor_id: user_default_actor_id
              }} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @converted_username,
               name: @name,
               domain: nil,
               user_id: ^user_id,
               id: actor_id
             } = Actors.get_local_actor_by_name(@converted_username)

      assert user_default_actor_id == actor_id
      assert email == @email
      assert role == :user
      refute is_nil(confirmed_at)
    end

    test "create a profile from username only" do
      New.run([@email, "--profile-username", @preferred_username])

      assert {:ok,
              %User{
                email: email,
                role: role,
                confirmed_at: confirmed_at,
                id: user_id,
                default_actor_id: user_default_actor_id
              }} = Users.get_user_by_email(@email)

      assert %Actor{
               preferred_username: @preferred_username,
               name: @preferred_username,
               domain: nil,
               user_id: ^user_id,
               id: actor_id
             } = Actors.get_local_actor_by_name(@preferred_username)

      assert user_default_actor_id == actor_id
      assert email == @email
      assert role == :user
      refute is_nil(confirmed_at)
    end
  end

  describe "delete user" do
    test "delete existing user" do
      insert(:user, email: @email)
      Delete.run([@email, "-y"])
      assert {:error, :user_not_found} = Users.get_user_by_email(@email)
    end

    test "full delete existing user" do
      insert(:user, email: @email)
      Delete.run([@email, "-y", "-k"])
      assert {:ok, %User{disabled: true}} = Users.get_user_by_email(@email)
    end

    test "delete non-existing user" do
      Delete.run([@email, "-y"])
      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Error: No such user"
    end
  end

  describe "show user" do
    test "show existing user" do
      %User{confirmed_at: confirmed_at, role: role} = user = insert(:user, email: @email)

      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)

      output =
        "Informations for the user #{@email}:\n  - account status: Activated on #{confirmed_at} (UTC)\n  - Role: #{role}\n  Identities (2):\n    - @#{actor1.preferred_username} / \n    - @#{actor2.preferred_username} / \n\n\n"

      Show.run([@email])
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == output
    end

    test "show non-existing user" do
      Show.run([@email])
      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Error: No such user"
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
               "An user has been modified with the following information:\n  - email: #{user.email}\n  - Role: #{user.role}\n  - account status: disabled\n"

      assert {:ok, %User{confirmed_at: confirmed_at}} = Users.get_user_by_email(@email)

      assert is_nil(confirmed_at)

      Modify.run([@email, "--enable"])
      assert_received {:mix_shell, :info, [output_received]}

      assert {:ok, %User{confirmed_at: confirmed_at}} = Users.get_user_by_email(@email)

      assert output_received ==
               "An user has been modified with the following information:\n  - email: #{user.email}\n  - Role: #{user.role}\n  - account status: Activated on #{confirmed_at} (UTC)\n"

      refute is_nil(confirmed_at)

      Modify.run([@email, "--enable"])

      assert {:ok, %User{confirmed_at: confirmed_at}} = Users.get_user_by_email(@email)

      refute is_nil(confirmed_at)
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == "No change has been made"
    end

    test "enable and disable at the same time" do
      Modify.run([@email, "--disable", "--enable"])
      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Can't use both --enable and --disable options at the same time."
    end

    @modified_email "modified@email.tld"

    test "change user's email" do
      user = insert(:user, email: @email)
      Modify.run([@email, "--email", @modified_email])

      assert_received {:mix_shell, :info, [output_received]}

      assert {:ok, %User{confirmed_at: confirmed_at, email: @modified_email}} =
               Users.get_user_by_email(@modified_email)

      assert output_received ==
               "An user has been modified with the following information:\n  - email: #{@modified_email}\n  - Role: #{user.role}\n  - account status: Activated on #{confirmed_at} (UTC)\n"
    end

    @modified_password "new one"

    test "change an user's password" do
      insert(:user, email: @email)
      Modify.run([@email, "--password", @modified_password])

      assert {:ok, %User{}} =
               Mobilizon.Service.Auth.MobilizonAuthenticator.login(@email, @modified_password)

      Modify.run([@email, "--password", "changed again"])

      assert {:error, :bad_password} =
               Mobilizon.Service.Auth.MobilizonAuthenticator.login(@email, @modified_password)
    end
  end
end
