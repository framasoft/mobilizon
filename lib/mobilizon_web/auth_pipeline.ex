defmodule MobilizonWeb.AuthPipeline do
  @moduledoc """
  Handles the app sessions
  """

  use Guardian.Plug.Pipeline,
    otp_app: :mobilizon,
    module: MobilizonWeb.Guardian,
    error_handler: MobilizonWeb.AuthErrorHandler

  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated)
  plug(Guardian.Plug.LoadResource, ensure: true)
end
