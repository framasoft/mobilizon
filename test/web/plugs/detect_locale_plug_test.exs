# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.DetectLocalePlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Mobilizon.Web.Plugs.DetectLocalePlug
  alias Plug.Conn

  test "use supported locale from `accept-language`" do
    conn =
      :get
      |> conn("/cofe")
      |> Conn.put_req_header(
        "accept-language",
        "ru, fr-CH, fr;q=0.9, en;q=0.8, *;q=0.5"
      )
      |> DetectLocalePlug.call([])

    assert %{detected_locale: "ru"} == conn.assigns
  end

  test "returns empty string if `accept-language` header is empty" do
    conn =
      :get
      |> conn("/cofe")
      |> Conn.put_req_header("accept-language", "tlh")
      |> DetectLocalePlug.call([])

    assert %{detected_locale: nil} == conn.assigns
  end
end
