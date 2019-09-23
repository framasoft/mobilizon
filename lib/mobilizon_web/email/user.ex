defmodule MobilizonWeb.Email.User do
  @moduledoc """
  Handles emails sent to users.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  import Bamboo.Phoenix

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

    subject =
      gettext(
        "Instructions to confirm your Mobilizon account on %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:token, confirmation_token)
    |> assign(:subject, subject)
    |> render("registration_confirmation.html")
    |> Email.premail()
  end

  @spec reset_password_email(User.t(), String.t()) :: Bamboo.Email.t()
  def reset_password_email(
        %User{email: email, reset_password_token: reset_password_token},
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Instructions to reset your password on %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:token, reset_password_token)
    |> assign(:subject, subject)
    |> render("password_reset.html")
    |> Email.premail()
  end
end
