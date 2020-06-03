defmodule Mobilizon.Web.Email.Group do
  @moduledoc """
  Handles emails sent about participation.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.{Email, Gettext}

  @doc """
  Send emails to local user
  """
  def send_invite_to_user(
        %Member{actor: %Actor{user_id: user_id}, parent: %Actor{} = group, role: :invited} =
          member,
        locale \\ "en"
      ) do
    with %User{email: email} <- Users.get_user!(user_id) do
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
      |> Email.Mailer.deliver_later()

      :ok
    end
  end

  # TODO : def send_confirmation_to_inviter()
end
