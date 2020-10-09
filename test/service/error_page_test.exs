defmodule Mobilizon.Service.ErrorPageTest do
  @moduledoc """
  Test the error page producer module
  """

  alias Mobilizon.Config
  alias Mobilizon.Service.ErrorPage

  use Mobilizon.DataCase

  describe "init/0" do
    test "renders an error page in the default language" do
      ErrorPage.init()
      path = Path.join(Application.app_dir(:mobilizon, "priv/errors"), "error.html")
      assert File.exists?(path)
      assert {:ok, data} = File.read(path)
      assert data =~ "This page is not correct"
    end

    test "uses the instance default language if defined" do
      Config.put([:instance, :default_language], "fr")
      ErrorPage.init()
      path = Path.join(Application.app_dir(:mobilizon, "priv/errors"), "error.html")
      assert File.exists?(path)
      assert {:ok, data} = File.read(path)
      refute data =~ "This page is not correct"
      assert data =~ "<html lang=\"fr\">"
      Config.put([:instance, :default_language], "en")
    end
  end
end
