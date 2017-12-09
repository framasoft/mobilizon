defmodule EventosWeb.AuthPipeline do

  use Guardian.Plug.Pipeline, otp_app: :eventos,
                              module: EventosWeb.Guradian,
                              error_handler: EventosWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, realm: :none
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true

end