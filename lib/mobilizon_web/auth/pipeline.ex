defmodule MobilizonWeb.Auth.Pipeline do
  @moduledoc """
  Handles the app sessions
  """

  use Guardian.Plug.Pipeline,
    otp_app: :mobilizon,
    module: MobilizonWeb.Auth.Guardian,
    error_handler: MobilizonWeb.Auth.ErrorHandler

  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource, allow_blank: true)
  plug(MobilizonWeb.Auth.Context)
end
