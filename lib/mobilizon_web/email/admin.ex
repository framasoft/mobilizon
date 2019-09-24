defmodule MobilizonWeb.Email.Admin do
  @moduledoc """
  Handles emails sent to admins.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  import Bamboo.Phoenix

  import MobilizonWeb.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User

  alias MobilizonWeb.Email

  @spec report(User.t(), Report.t(), String.t()) :: Bamboo.Email.t()
  def report(%User{email: email}, %Report{} = report, locale \\ "en") do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "New report on Mobilizon instance %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:subject, subject)
    |> assign(:report, report)
    |> render(:report)
  end
end
