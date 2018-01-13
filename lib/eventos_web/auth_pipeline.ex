defmodule EventosWeb.AuthPipeline do

  use Guardian.Plug.Pipeline, otp_app: :eventos,
                              module: EventosWeb.Guardian,
                              error_handler: EventosWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true

end