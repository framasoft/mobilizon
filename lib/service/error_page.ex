defmodule Mobilizon.Service.ErrorPage do
  @moduledoc """
  Render an error page
  """

  @spec init :: :ok | {:error, File.posix()}
  def init do
    render_error_page()
  end

  @spec render_error_page :: :ok | {:error, File.posix()}
  defp render_error_page do
    content =
      Phoenix.View.render_to_string(Mobilizon.Web.ErrorView, "500.html", conn: %Plug.Conn{})

    path = Path.join(Application.app_dir(:mobilizon, "priv/errors"), "error.html")
    File.write(path, content)
  end
end
