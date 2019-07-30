# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Mobilizon.RelayTest do
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Actors
  alias Mobilizon.Service.ActivityPub.Relay
  use Mobilizon.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "running follow" do
    test "relay is followed" do
      use_cassette "relay/fetch_relay_follow" do
        target_instance = "http://localhost:8080/actor"

        Mix.Tasks.Mobilizon.Relay.run(["follow", target_instance])

        local_actor = Relay.get_actor()
        assert local_actor.url =~ "/relay"

        {:ok, target_actor} = Actors.get_actor_by_url(target_instance)
        refute is_nil(target_actor.domain)

        assert Actor.following?(local_actor, target_actor)
      end
    end
  end

  describe "running unfollow" do
    test "relay is unfollowed" do
      use_cassette "relay/fetch_relay_unfollow" do
        target_instance = "http://localhost:8080/actor"

        Mix.Tasks.Mobilizon.Relay.run(["follow", target_instance])

        %Actor{} = local_actor = Relay.get_actor()
        {:ok, %Actor{} = target_actor} = Actors.get_actor_by_url(target_instance)
        assert %Follower{} = Actor.following?(local_actor, target_actor)

        Mix.Tasks.Mobilizon.Relay.run(["unfollow", target_instance])

        refute Actor.following?(local_actor, target_actor)
      end
    end
  end
end
