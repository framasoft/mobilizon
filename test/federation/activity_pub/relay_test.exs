# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Federation.ActivityPub.RelayTest do
  use Mobilizon.DataCase

  alias Mobilizon.Federation.ActivityPub.Relay

  test "gets an actor for the relay" do
    actor = Relay.get_actor()

    assert actor.url =~ "/relay"
  end
end
