# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.SetLocalePlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Mobilizon.Web.Plugs.SetLocalePlug
  alias Plug.Conn

  test "default locale is `en`" do
    conn =
      :get
      |> conn("/cofe")
      |> SetLocalePlug.call([])

    assert "en" == Gettext.get_locale()
    assert %{locale: "en"} == conn.assigns
  end

  test "use supported locale from `accept-language`" do
    conn =
      :get
      |> conn("/cofe")
      |> Conn.put_req_header(
        "accept-language",
        "ru, fr-CH, fr;q=0.9, en;q=0.8, *;q=0.5"
      )
      |> SetLocalePlug.call([])

    assert "ru" == Gettext.get_locale()
    assert %{locale: "ru"} == conn.assigns
  end

  test "use default locale if locale from `accept-language` is not supported" do
    conn =
      :get
      |> conn("/cofe")
      |> Conn.put_req_header("accept-language", "tlh")
      |> SetLocalePlug.call([])

    assert "en" == Gettext.get_locale()
    assert %{locale: "en"} == conn.assigns
  end
end
