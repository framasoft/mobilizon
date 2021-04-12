# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Mobilizon.RelayTest do
  use Mobilizon.DataCase

  alias Mix.Tasks.Mobilizon.Relay.{Follow, Unfollow}

  alias Mobilizon.Federation.ActivityPub.Relay
  import Mock

  Mix.shell(Mix.Shell.Process)

  @target_instance "mobilizon1.com"

  @output_1 "Requested to follow #{@target_instance}"
  @error_1 "Some error"
  @error_msg_1 "Error while following #{@target_instance}: \"#{@error_1}\""
  @error_msg_1_unfollow "Error while unfollowing #{@target_instance}: \"#{@error_1}\""
  @error_msg_2 "mobilizon.relay.follow requires an instance hostname as arguments"
  @error_msg_2_unfollow "mobilizon.relay.unfollow requires an instance hostname as arguments"

  @output_2 "Unfollowed #{@target_instance}"

  describe "running follow" do
    test "relay is followed" do
      with_mock Relay, [:passthrough], follow: fn @target_instance -> {:ok, nil, nil} end do
        Follow.run([@target_instance])
        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == @output_1
      end
    end

    test "returns an error" do
      with_mock Relay, [:passthrough], follow: fn @target_instance -> {:error, @error_1} end do
        Follow.run([@target_instance])
        assert_received {:mix_shell, :error, [output_received]}
        assert output_received == @error_msg_1
      end
    end

    test "without arguments" do
      Follow.run([])
      assert_received {:mix_shell, :error, [output_received]}
      assert output_received == @error_msg_2
    end
  end

  describe "running unfollow" do
    test "relay is unfollowed" do
      with_mock Relay, [:passthrough], unfollow: fn @target_instance -> {:ok, nil, nil} end do
        Unfollow.run([@target_instance])

        assert_received {:mix_shell, :info, [output_received]}
        assert output_received == @output_2
      end
    end

    test "returns an error" do
      with_mock Relay, [:passthrough], unfollow: fn @target_instance -> {:error, @error_1} end do
        Unfollow.run([@target_instance])

        assert_received {:mix_shell, :error, [output_received]}
        assert output_received == @error_msg_1_unfollow
      end
    end

    test "without arguments" do
      Unfollow.run([])
      assert_received {:mix_shell, :error, [output_received]}
      assert output_received == @error_msg_2_unfollow
    end
  end
end
