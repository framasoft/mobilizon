defmodule Mobilizon.Email.User do
  @moduledoc """
  Handles emails sent to users
  """
  alias Mobilizon.Users.User

  import Bamboo.Email
  import Bamboo.Phoenix
  use Bamboo.Phoenix, view: Mobilizon.EmailView
  import MobilizonWeb.Gettext

  def confirmation_email(%User{} = user, locale \\ "en") do
    Gettext.put_locale(locale)
    instance_url = get_config(:instance)

    base_email()
    |> to(user.email)
    |> subject(
      gettext("Mobilizon: Confirmation instructions for %{instance}", instance: instance_url)
    )
    |> put_header("Reply-To", get_config(:email_reply_to))
    |> assign(:token, user.confirmation_token)
    |> assign(:instance, instance_url)
    |> render(:registration_confirmation)
  end

  def reset_password_email(%User{} = user, locale \\ "en") do
    Gettext.put_locale(locale)
    instance_url = get_config(:hostname)

    base_email()
    |> to(user.email)
    |> subject(
      gettext(
        "Mobilizon: Reset your password on %{instance} instructions",
        instance: instance_url
      )
    )
    |> put_header("Reply-To", get_config(:email_reply_to))
    |> assign(:token, user.reset_password_token)
    |> assign(:instance, instance_url)
    |> render(:password_reset)
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
