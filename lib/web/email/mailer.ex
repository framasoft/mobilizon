defmodule Mobilizon.Web.Email.Mailer do
  @moduledoc """
  Mobilizon Mailer.
  """
  use Swoosh.Mailer, otp_app: :mobilizon
  alias Mobilizon.Service.ErrorReporting.Sentry

  @spec send_email(Swoosh.Email.t()) :: Swoosh.Email.t()
  def send_email(email) do
    Mobilizon.Web.Email.Mailer.deliver(email)
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end
end
