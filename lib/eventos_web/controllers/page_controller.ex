defmodule EventosWeb.PageController do
  use EventosWeb, :controller

  plug :put_layout, false

  def index(conn, _params) do
    render conn, "index.html"
  end
end
