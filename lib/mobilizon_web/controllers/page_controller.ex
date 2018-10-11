defmodule MobilizonWeb.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use MobilizonWeb, :controller

  plug(:put_layout, false)

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "priv/static/index.html")
  end
end
