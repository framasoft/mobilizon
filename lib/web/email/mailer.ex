defmodule Mobilizon.Web.Email.Mailer do
  @moduledoc """
  Mobilizon Mailer.
  """
  use Swoosh.Mailer, otp_app: :mobilizon
  alias Mobilizon.Service.ErrorReporting.Sentry
  require Logger

  @spec send_email(Swoosh.Email.t()) :: {:ok, term} | {:error, term}
  def send_email(email) do
    Logger.debug(
      "Mailer options #{inspect(Keyword.drop(Application.get_env(:mobilizon, Mobilizon.Web.Email.Mailer), [:tls_options]))}"
    )

    Logger.debug("Sending mail, #{inspect(email)}")
    res = Mobilizon.Web.Email.Mailer.deliver(email)
    Logger.debug("Return from sending mail #{inspect(res)}")
    res
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end
end
