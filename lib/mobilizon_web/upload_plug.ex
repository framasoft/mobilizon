defmodule MobilizonWeb.UploadPlug do
  use Plug.Builder

  plug(Plug.Static,
    at: "/",
    from: {:mobilizon, "./uploads"}
  )

  #   only: ~w(images robots.txt)
  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
