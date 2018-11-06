defmodule MobilizonWeb.AuthPipeline do
  @moduledoc """
  Handles the app sessions
  """

  use Guardian.Plug.Pipeline,
    otp_app: :mobilizon,
    module: MobilizonWeb.Guardian,
    error_handler: MobilizonWeb.AuthErrorHandler

  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource, allow_blank: true)
  plug(MobilizonWeb.Context)
end
