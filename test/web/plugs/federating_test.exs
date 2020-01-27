# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plug.FederatingTest do
  use Mobilizon.Web.ConnCase

  alias Mobilizon.Web.Plugs.Federating

  test "returns and halt the conn when federating is disabled" do
    Mobilizon.Config.put([:instance, :federating], false)

    conn = Federating.call(build_conn(), %{})

    assert conn.status == 404
    assert conn.halted
  end

  test "does nothing when federating is enabled" do
    Mobilizon.Config.put([:instance, :federating], true)

    conn = Federating.call(build_conn(), %{})

    refute conn.status
    refute conn.halted
  end
end
