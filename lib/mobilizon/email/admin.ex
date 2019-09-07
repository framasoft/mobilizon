defmodule Mobilizon.Email.Admin do
  @moduledoc """
  Handles emails sent to admins.
  """

  use Bamboo.Phoenix, view: Mobilizon.EmailView

  import Bamboo.{Email, Phoenix}

  import MobilizonWeb.Gettext

  alias Mobilizon.{Config, Email}
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User

  @spec report(User.t(), Report.t(), String.t()) :: Bamboo.Email.t()
  def report(%User{email: email}, %Report{} = report, locale \\ "en") do
    Gettext.put_locale(locale)

    instance_url = Config.instance_url()

    subject =
      gettext(
        "Mobilizon: New report on instance %{instance}",
        instance: instance_url
      )

    Email.base_email()
    |> to(email)
    |> subject(subject)
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> assign(:report, report)
    |> assign(:instance, instance_url)
    |> render(:report)
  end
end
