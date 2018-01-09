defmodule EventosWeb.AppController do
  use EventosWeb, :controller

  plug :put_layout, false

  def app(conn, _params) do
    render conn, "index.html"
  end
end
