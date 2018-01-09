defmodule EventosWeb.PageController do
  use EventosWeb, :controller
  import Logger

  def index(conn, _params) do
    render conn, "index.html"
  end
end
