defmodule Mobilizon.Web.Email.Member do
  @moduledoc """
  Handles emails sent about group members.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email

  @doc """
  Send emails to local user
  """
  @spec send_invite_to_user(Member.t()) :: :ok
  def send_invite_to_user(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_invite_to_user(
        %Member{actor: %Actor{user_id: user_id}, parent: %Actor{} = group, role: :invited} =
          member
      ) do
    with %User{email: email} = user <- Users.get_user!(user_id) do
      locale = Map.get(user, :locale, "en")
      Gettext.put_locale(locale)
      %Actor{name: invited_by_name} = inviter = Actors.get_actor(member.invited_by_id)

      subject =
        gettext(
          "You have been invited by %{inviter} to join group %{group}",
          inviter: invited_by_name,
          group: group.name
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:inviter, inviter)
      |> assign(:group, group)
      |> assign(:subject, subject)
      |> render(:group_invite)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end

  # Only send notification to local members
  def send_notification_to_removed_member(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_notification_to_removed_member(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{} = group,
        role: :rejected
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "You have been removed from group %{group}",
          group: group.name
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:group, group)
      |> assign(:subject, subject)
      |> render(:group_member_removal)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end

  # TODO : def send_confirmation_to_inviter()
end
