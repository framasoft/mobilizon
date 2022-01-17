defmodule Mobilizon.Web.Email.Admin do
  @moduledoc """
  Handles emails sent to admins.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix

  import Mobilizon.Web.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Email

  @spec report(User.t(), Report.t()) :: Bamboo.Email.t()
  def report(%User{email: email} = user, %Report{} = report) do
    locale = Map.get(user, :locale, "en")
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

  @spec user_email_change_old(User.t(), String.t()) :: Bamboo.Email.t()
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

    Email.base_email(to: old_email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:new_email, new_email)
    |> assign(:old_email, old_email)
    |> assign(:offer_unsupscription, false)
    |> render(:admin_user_email_changed_old)
  end

  @spec user_email_change_new(User.t(), String.t()) :: Bamboo.Email.t()
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

    Email.base_email(to: new_email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:old_email, old_email)
    |> assign(:new_email, new_email)
    |> assign(:offer_unsupscription, false)
    |> render(:admin_user_email_changed_new)
  end

  @spec user_role_change(User.t(), atom()) :: Bamboo.Email.t()
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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:old_role, old_role)
    |> assign(:new_role, new_role)
    |> assign(:offer_unsupscription, false)
    |> render(:admin_user_role_changed)
  end

  @spec user_confirmation(User.t()) :: Bamboo.Email.t()
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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:offer_unsupscription, false)
    |> render(:admin_user_confirmation)
  end
end
