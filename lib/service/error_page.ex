defmodule Mobilizon.Service.ErrorPage do
  @moduledoc """
  Render an error page
  """

  def init do
    render_error_page()
  end

  defp render_error_page do
    content =
      Phoenix.View.render_to_string(Mobilizon.Web.ErrorView, "500.html", conn: %Plug.Conn{})

    path = Path.join(Application.app_dir(:mobilizon, "priv/errors"), "error.html")
    File.write(path, content)
  end
end
