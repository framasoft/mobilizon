defmodule Mobilizon.Web.Email.Admin do
  @moduledoc """
  Handles emails sent to admins.
  """

  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Email

  @spec report(User.t(), Report.t()) :: Swoosh.Email.t()
  def report(%User{email: email} = user, %Report{} = report) do
    locale = Map.get(user, :locale, "en")
    Gettext.put_locale(locale)

    subject =
      gettext(
        "New report on Mobilizon instance %{instance}",
        instance: Config.instance_name()
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:report, %{locale: locale, subject: subject, report: report})
  end

  @spec user_email_change_old(User.t(), String.t()) :: Swoosh.Email.t()
  def user_email_change_old(
        %User{
          locale: user_locale,
          email: new_email
        },
        old_email
      ) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "An administrator manually changed the email attached to your account on %{instance}",
        instance: Config.instance_name()
      )

    [to: old_email, subject: subject]
    |> Email.base_email()
    |> render_body(:admin_user_email_changed_old, %{
      locale: user_locale,
      subject: subject,
      new_email: new_email,
      old_email: old_email,
      offer_unsupscription: false
    })
  end

  @spec user_email_change_new(User.t(), String.t()) :: Swoosh.Email.t()
  def user_email_change_new(
        %User{
          locale: user_locale,
          email: new_email
        },
        old_email
      ) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "An administrator manually changed the email attached to your account on %{instance}",
        instance: Config.instance_name()
      )

    [to: old_email, subject: subject]
    |> Email.base_email()
    |> render_body(:admin_user_email_changed_new, %{
      locale: user_locale,
      subject: subject,
      new_email: new_email,
      old_email: old_email,
      offer_unsupscription: false
    })
  end

  @spec user_role_change(User.t(), atom()) :: Swoosh.Email.t()
  def user_role_change(
        %User{
          locale: user_locale,
          email: email,
          role: new_role
        },
        old_role
      ) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "An administrator updated your role on %{instance}",
        instance: Config.instance_name()
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:admin_user_role_changed, %{
      locale: user_locale,
      subject: subject,
      old_role: old_role,
      new_role: new_role,
      offer_unsupscription: false
    })
  end

  @spec user_confirmation(User.t()) :: Swoosh.Email.t()
  def user_confirmation(%User{
        locale: user_locale,
        email: email
      }) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "An administrator confirmed your account on %{instance}",
        instance: Config.instance_name()
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:admin_user_confirmation, %{
      locale: user_locale,
      subject: subject,
      offer_unsupscription: false
    })
  end

  @spec email_configuration_test(String.t(), Keyword.t()) :: Swoosh.Email.t()
  def email_configuration_test(email, options) do
    locale = Keyword.get(options, :locale, "en")
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Email configuration test for %{instance}",
        instance: Config.instance_name()
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:email_configuration_test, %{
      locale: locale,
      subject: subject,
      offer_unsupscription: false
    })
  end
end
