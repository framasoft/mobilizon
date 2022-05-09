defmodule Mix.Tasks.Mobilizon.Actors.DeleteTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Actors.Delete

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Users.User

  Mix.shell(Mix.Shell.Process)

  @preferred_username "toto"
  @name "Léo Pandaï"

  describe "delete local profile" do
    setup do
      %User{} = user = insert(:user)

      %Actor{} =
        profile = insert(:actor, user: user, preferred_username: @preferred_username, name: @name)

      {:ok, user: user, profile: profile}
    end

    test "delete when username isn't set" do
      Delete.run([])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "mobilizon.actors.delete requires an username or a federated username as argument"
    end

    test "delete when no actor can't be found" do
      Delete.run(["other_one"])

      # Debug message
      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "No actor found with this username"
    end

    test "delete with -y", %{profile: profile} do
      Delete.run([@preferred_username, "-y"])

      assert_received {:mix_shell, :info, [message]}
      refute_received {:mix_shell, :yes?}

      assert message =~
               "The actor #{Actor.display_name_and_username(profile)} has been deleted"

      assert nil == Actors.get_actor_by_name(@preferred_username)
    end

    test "delete while accepting", %{profile: profile} do
      display_name = Actor.display_name_and_username(profile)
      send(self(), {:mix_shell_input, :yes?, true})
      send(self(), {:mix_shell_input, :yes?, true})

      Delete.run([@preferred_username])

      assert_received {:mix_shell, :yes?, [input]}

      assert input ==
               "All content by this profile or group will be deleted. Continue with deleting #{display_name}?"

      assert_received {:mix_shell, :yes?, [input2]}

      assert input2 ==
               "This profile is the only one user #{profile.user.email} has. Mobilizon will invite the user to create a new profile on their next login. If you want to remove the whole user account, use the `mobilizon.users.delete` command. Continue deleting?"

      assert_received {:mix_shell, :info, [message2]}
      assert message2 =~ "The actor #{display_name} has been deleted"

      assert nil == Actors.get_actor_by_name(@preferred_username)
    end
  end

  describe "delete group" do
    @group_username "already_there"
    @profile_username "theo"

    setup do
      group = insert(:group, preferred_username: @group_username)
      profile = insert(:actor, preferred_username: @profile_username)
      insert(:member, parent: group, actor: profile, role: :administrator)
      insert(:member, parent: group, role: :member)
      {:ok, group: group, profile: profile}
    end

    test "when everything is accepted", %{group: group} do
      display_name = Actor.display_name_and_username(group)
      send(self(), {:mix_shell_input, :yes?, true})
      send(self(), {:mix_shell_input, :yes?, true})
      Delete.run([@group_username])

      assert_received {:mix_shell, :yes?, [input]}

      assert input ==
               "All content by this profile or group will be deleted. Continue with deleting #{display_name}?"

      assert_received {:mix_shell, :yes?, [input2]}
      assert input2 == "Group #{display_name} has 2 members and 0 followers. Continue deleting?"

      assert_received {:mix_shell, :info, [message]}
      assert message =~ "Group members will be notified of the group deletion."
      assert_received {:mix_shell, :info, [message2]}
      assert message2 =~ "The actor #{display_name} has been deleted"

      assert nil == Actors.get_actor_by_name(@preferred_username)
    end

    test "when something is rejected", %{group: group} do
      display_name = Actor.display_name_and_username(group)
      send(self(), {:mix_shell_input, :yes?, false})
      Delete.run([@group_username])

      assert_received {:mix_shell, :yes?, [input]}

      assert input ==
               "All content by this profile or group will be deleted. Continue with deleting #{display_name}?"

      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Actor has not been deleted."

      assert nil == Actors.get_actor_by_name(@preferred_username)
    end

    test "with assume_yes option", %{group: group} do
      display_name = Actor.display_name_and_username(group)
      Delete.run([@group_username, "-y"])

      refute_received {:mix_shell, :yes?}

      assert_received {:mix_shell, :info, [message]}
      assert message =~ "Group members will be notified of the group deletion."
      assert_received {:mix_shell, :info, [message2]}
      assert message2 =~ "The actor #{display_name} has been deleted"

      assert nil == Actors.get_actor_by_name(@preferred_username)
    end

    test "fails when called for an internal actor" do
      Relay.get_actor()
      Delete.run(["relay", "-y"])

      assert_received {:mix_shell, :error, [message]}
      assert message =~ "This actor can't be deleted."
    end
  end

  describe "delete something else" do
    @actor_username "whatever"

    setup do
      actor = insert(:actor, preferred_username: @actor_username, type: :Application)
      {:ok, actor: actor}
    end

    test "fails", %{actor: actor} do
      display_name = Actor.display_name_and_username(actor)
      send(self(), {:mix_shell_input, :yes?, true})
      Delete.run([@actor_username])
      assert_received {:mix_shell, :yes?, [input]}

      assert input ==
               "All content by this profile or group will be deleted. Continue with deleting #{display_name}?"

      assert_received {:mix_shell, :error, [message2]}
      assert message2 =~ "Actor has not been deleted."
    end
  end
end
