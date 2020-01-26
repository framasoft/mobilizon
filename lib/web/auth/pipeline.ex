defmodule Mobilizon.Web.Auth.Pipeline do
  @moduledoc """
  Handles the app sessions
  """

  use Guardian.Plug.Pipeline,
    otp_app: :mobilizon,
    module: Mobilizon.Web.Auth.Guardian,
    error_handler: Mobilizon.Web.Auth.ErrorHandler

  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource, allow_blank: true)
  plug(Mobilizon.Web.Auth.Context)
end
