defmodule EventosWeb.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use EventosWeb, :controller

  plug(:put_layout, false)

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
