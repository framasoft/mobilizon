defmodule Mobilizon.Web.GettextTest do
  use ExUnit.Case, async: true

  alias Mobilizon.Config
  alias Mobilizon.Web.Gettext, as: GettextBackend

  describe "test determine_best_locale/1" do
    setup do
      Config.put([:instance, :default_language], "en")
      :ok
    end

    test "with empty string returns the default locale" do
      assert GettextBackend.determine_best_locale("") == "en"
    end

    test "with empty string returns the default configured locale" do
      Config.put([:instance, :default_language], "es")
      assert GettextBackend.determine_best_locale("") == "es"
    end

    test "with empty string returns english as a proper fallback if the default configured locale is nil" do
      Config.put([:instance, :default_language], nil)
      assert GettextBackend.determine_best_locale("") == "en"
    end

    test "returns fallback with an unexisting locale" do
      assert GettextBackend.determine_best_locale("yolo") == "en"
    end

    test "maps the correct part if the locale has multiple ones" do
      assert GettextBackend.determine_best_locale("fr_CA") == "fr"
    end

    test "returns the locale if valid" do
      assert GettextBackend.determine_best_locale("es") == "es"
    end
  end
end
