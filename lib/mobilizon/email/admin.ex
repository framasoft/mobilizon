defmodule Mobilizon.Email.Admin do
  @moduledoc """
  Handles emails sent to admins
  """
  alias Mobilizon.Users.User

  import Bamboo.Email
  import Bamboo.Phoenix
  use Bamboo.Phoenix, view: Mobilizon.EmailView
  import MobilizonWeb.Gettext
  alias Mobilizon.Reports.Report

  def report(%User{email: email} = _user, %Report{} = report, locale \\ "en") do
    Gettext.put_locale(locale)
    instance_url = get_config(:hostname)

    base_email()
    |> to(email)
    |> subject(gettext("Mobilizon: New report on instance %{instance}", instance: instance_url))
    |> put_header("Reply-To", get_config(:email_reply_to))
    |> assign(:report, report)
    |> assign(:instance, instance_url)
    |> render(:report)
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from(get_config(:email_from))
    |> put_html_layout({Mobilizon.EmailView, "email.html"})
    |> put_text_layout({Mobilizon.EmailView, "email.text"})
  end

  @spec get_config(atom()) :: any()
  defp get_config(key) do
    Mobilizon.CommonConfig.instance_config() |> Keyword.get(key)
  end
end
