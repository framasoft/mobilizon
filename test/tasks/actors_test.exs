defmodule Mix.Tasks.Mobilizon.ActorsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Actors.Show

  alias Mobilizon.Actors.Actor

  Mix.shell(Mix.Shell.Process)

  @username "someone"
  @domain "somewhere.tld"

  describe "show actor" do
    test "show existing local actor" do
      %Actor{} = actor = insert(:actor, preferred_username: @username)

      output = """
      Informations for the actor #{@username}:
        - Type: Person
        - Domain: Local
        - Name: #{actor.name}
        - Summary: #{actor.summary}
        - User: #{actor.user.email}
      """

      Show.run([@username])
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == output
    end

    test "show existing remote actor" do
      %Actor{} = actor = insert(:actor, preferred_username: @username, user: nil, domain: @domain)

      output = """
      Informations for the actor #{@username}:
        - Type: Person
        - Domain: #{@domain}
        - Name: #{actor.name}
        - Summary: #{actor.summary}
        - User: Remote
      """

      Show.run(["#{@username}@#{@domain}"])
      assert_received {:mix_shell, :info, [output_received]}
      assert output_received == output
    end

    test "show non-existing actor" do
      Show.run([@username])
      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Error: No such actor"
    end
  end
end
