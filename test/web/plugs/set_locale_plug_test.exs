# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.SetLocalePlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Mobilizon.Config
  alias Mobilizon.Web.Plugs.SetLocalePlug
  alias Plug.Conn

  describe "test assigning locale to conn" do
    test "use supported locale from `accept-language`" do
      conn =
        :get
        |> conn("/cofe")
        |> assign(:detected_locale, "ru")
        |> SetLocalePlug.call([])

      assert "ru" == Gettext.get_locale()
      assert %{locale: "ru", detected_locale: "ru"} == conn.assigns
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

  describe "test getting default locale from instance" do
    test "default locale is `en`" do
      conn =
        :get
        |> conn("/cofe")
        |> SetLocalePlug.call([])

      assert "en" == Gettext.get_locale()
      assert %{locale: "en"} == conn.assigns
    end

    test "with empty string returns the default configured locale" do
      Config.put([:instance, :default_language], "es")

      conn =
        :get
        |> conn("/cofe")
        |> SetLocalePlug.call([])

      assert %{locale: "es"} == conn.assigns

      Config.put([:instance, :default_language], "en")
    end

    test "with empty string returns english as a proper fallback if the default configured locale is nil" do
      Config.put([:instance, :default_language], nil)

      conn =
        :get
        |> conn("/cofe")
        |> SetLocalePlug.call([])

      assert %{locale: "en"} == conn.assigns

      Config.put([:instance, :default_language], "en")
    end
  end

  describe "test determine_best_locale/1" do
    test "with empty string returns the default locale" do
      assert SetLocalePlug.determine_best_locale("") == nil
    end

    test "returns fallback with an unexisting locale" do
      assert SetLocalePlug.determine_best_locale("yolo") == nil
    end

    test "maps the correct part if the locale has multiple ones" do
      assert SetLocalePlug.determine_best_locale("fr_CA") == "fr"
    end

    test "returns the locale if valid" do
      assert SetLocalePlug.determine_best_locale("es") == "es"
    end
  end
end
