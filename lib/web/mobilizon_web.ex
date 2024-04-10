defmodule Mobilizon.Web do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use Mobilizon.Web, :controller
      use Mobilizon.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do: ~w(index.html service-worker.js css fonts img js robots.txt assets)

  def controller do
    quote do
      use Phoenix.Controller, namespace: Mobilizon.Web
      import Plug.Conn
      import Mobilizon.Web.Gettext
      alias Mobilizon.Web.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/web/templates",
        pattern: "**/*",
        namespace: Mobilizon.Web

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Phoenix.View
      import Mobilizon.Web.ErrorHelpers
      import Mobilizon.Web.Gettext
      alias Mobilizon.Web.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Mobilizon.Web.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Mobilizon.Web.Endpoint,
        router: Mobilizon.Web.Router,
        statics: Mobilizon.Web.static_paths()
    end
  end
end
