defmodule EventosWeb.PageController do
  use EventosWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
