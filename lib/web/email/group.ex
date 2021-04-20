defmodule Mobilizon.Web.Email.Group do
  @moduledoc """
  Handles emails sent about participation.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.{Actors, Config, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.{Email, Gettext}

  @doc """
  Send emails to local user
  """
  @spec send_invite_to_user(Member.t(), String.t()) :: :ok
  def send_invite_to_user(member, locale \\ "en")
  def send_invite_to_user(%Member{actor: %Actor{user_id: nil}}, _locale), do: :ok

  def send_invite_to_user(
        %Member{actor: %Actor{user_id: user_id}, parent: %Actor{} = group, role: :invited} =
          member,
        locale
      ) do
    with %User{email: email} = user <- Users.get_user!(user_id) do
      locale = Map.get(user, :locale, locale)
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

  @member_roles [:administrator, :moderator, :member]
  def send_group_suspension_notification(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_group_suspension_notification(%Member{role: role}) when role not in @member_roles,
    do: :ok

  def send_group_suspension_notification(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{domain: nil} = group,
        role: member_role
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)
      instance = Config.instance_name()

      subject =
        gettext(
          "The group %{group} has been suspended on %{instance}",
          group: group.name,
          instance: instance
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:group, group)
      |> assign(:role, member_role)
      |> assign(:subject, subject)
      |> assign(:instance, instance)
      |> render(:group_suspension)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end

  def send_group_deletion_notification(%Member{actor: %Actor{user_id: nil}}, _author), do: :ok

  def send_group_deletion_notification(%Member{role: role}, _author)
      when role not in @member_roles,
      do: :ok

  def send_group_deletion_notification(
        %Member{
          actor: %Actor{user_id: user_id, id: actor_id},
          parent: %Actor{domain: nil} = group,
          role: member_role
        },
        %Actor{id: author_id} = author
      ) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id),
         {:member_not_author, true} <- {:member_not_author, author_id !== actor_id} do
      Gettext.put_locale(locale)
      instance = Config.instance_name()

      subject =
        gettext(
          "The group %{group} has been deleted on %{instance}",
          group: group.name,
          instance: instance
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:group, group)
      |> assign(:role, member_role)
      |> assign(:subject, subject)
      |> assign(:instance, instance)
      |> assign(:author, author)
      |> render(:group_deletion)
      |> Email.Mailer.send_email_later()

      :ok
    else
      # Skip if it's the author itself
      {:member_not_author, _} ->
        :ok
    end
  end
end
