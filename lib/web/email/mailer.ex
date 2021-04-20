defmodule Mobilizon.Web.Email.Mailer do
  @moduledoc """
  Mobilizon Mailer.
  """
  use Bamboo.Mailer, otp_app: :mobilizon

  def send_email_later(email) do
    Mobilizon.Web.Email.Mailer.deliver_later!(email)
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end

  def send_email(email) do
    Mobilizon.Web.Email.Mailer.deliver_now!(email)
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end
end
