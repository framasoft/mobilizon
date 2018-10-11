defmodule MobilizonWeb.WebFingerController do
  use MobilizonWeb, :controller

  alias Mobilizon.Service.WebFinger

  def host_meta(conn, _params) do
    xml = WebFinger.host_meta()

    conn
    |> put_resp_content_type("application/xrd+xml")
    |> send_resp(200, xml)
  end

  def webfinger(conn, %{"resource" => resource}) do
    with {:ok, response} <- WebFinger.webfinger(resource, "JSON") do
      json(conn, response)
    else
      _e -> send_resp(conn, 404, "Couldn't find user")
    end
  end
end
