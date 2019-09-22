defmodule MobilizonWeb.Email.User do
  @moduledoc """
  Handles emails sent to users.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  import Bamboo.{Email, Phoenix}

  import MobilizonWeb.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Users.User

  alias MobilizonWeb.Email

  @spec confirmation_email(User.t(), String.t()) :: Bamboo.Email.t()
  def confirmation_email(
        %User{email: email, confirmation_token: confirmation_token},
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    instance_url = Config.instance_url()

    subject =
      gettext(
        "Mobilizon: Confirmation instructions for %{instance}",
        instance: instance_url
      )

    Email.base_email()
    |> to(email)
    |> subject(subject)
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> assign(:token, confirmation_token)
    |> assign(:instance, instance_url)
    |> render(:registration_confirmation)
  end

  @spec reset_password_email(User.t(), String.t()) :: Bamboo.Email.t()
  def reset_password_email(
        %User{email: email, reset_password_token: reset_password_token},
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    instance_url = Config.instance_url()

    subject =
      gettext(
        "Mobilizon: Reset your password on %{instance} instructions",
        instance: instance_url
      )

    Email.base_email()
    |> to(email)
    |> subject(subject)
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> assign(:token, reset_password_token)
    |> assign(:instance, instance_url)
    |> render(:password_reset)
  end
end
