defmodule Eventos.Email.User do

  alias Eventos.Actors.User

  import Bamboo.Email
  import Bamboo.Phoenix
  use Bamboo.Phoenix, view: Eventos.EmailView
  import EventosWeb.Gettext

  def confirmation_email(%User{} = user, locale \\ "en") do
    Gettext.put_locale(locale)
    instance_url = get_config(:instance)
    base_email()
    |> to(user.email)
    |> subject(gettext "Peakweaver: Confirmation instructions for %{instance}", instance: instance_url)
    |> put_header("Reply-To", get_config(:reply_to))
    |> assign(:token, user.confirmation_token)
    |> assign(:instance, instance_url)
    |> render(:registration_confirmation)
  end

  def reset_password_email(%User{} = user, locale \\ "en") do
    Gettext.put_locale(locale)
    instance_url = get_config(:instance)
    base_email()
    |> to(user.email)
    |> subject(gettext "Peakweaver: Reset your password on %{instance} instructions", instance: instance_url)
    |> put_header("Reply-To", get_config(:reply_to))
    |> assign(:token, user.reset_password_token)
    |> assign(:instance, instance_url)
    |> render(:password_reset)
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from(Application.get_env(:eventos, EventosWeb.Endpoint)[:email_from])
    |> put_html_layout({Eventos.EmailView, "email.html"})
    |> put_text_layout({Eventos.EmailView, "email.text"})
  end

  @spec get_config(atom()) :: any()
  defp get_config(key) do
    _config = Application.get_env(:eventos, EventosWeb.Endpoint) |> Keyword.get(key)
  end
end
