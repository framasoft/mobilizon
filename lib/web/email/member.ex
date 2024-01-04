defmodule Mobilizon.Web.Email.Member do
  @moduledoc """
  Handles emails sent about group members.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

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

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:group_invite, %{
        locale: locale,
        inviter: inviter,
        group: group,
        subject: subject
      })
      |> Email.Mailer.send_email()

      :ok
    end
  end

  # Only send notification to local members
  def send_notification_to_approved_member(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_notification_to_approved_member(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{} = group
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "Your membership request for group %{group} has been approved",
          group: Actor.display_name(group)
        )

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:group_membership_approval, %{locale: locale, group: group, subject: subject})
      |> Email.Mailer.send_email()

      :ok
    end
  end

  # Only send notification to local members
  def send_notification_to_removed_member(%Member{actor: %Actor{user_id: nil}}), do: :ok

  # Member rejection
  def send_notification_to_removed_member(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{} = group,
        role: :not_approved
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "Your membership request for group %{group} has been rejected",
          group: Actor.display_name(group)
        )

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:group_membership_rejection, %{
        locale: locale,
        group: group,
        subject: subject
      })
      |> Email.Mailer.send_email()

      :ok
    end
  end

  def send_notification_to_removed_member(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{} = group
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "You have been removed from group %{group}",
          group: Actor.display_name(group)
        )

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:group_member_removal, %{locale: locale, group: group, subject: subject})
      |> Email.Mailer.send_email()

      :ok
    end
  end
end
