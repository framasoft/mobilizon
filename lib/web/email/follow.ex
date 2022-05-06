defmodule Mobilizon.Web.Email.Follow do
  @moduledoc """
  Handles emails sent about (instance) follow.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Users
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email

  @doc """
  Send follow notification to admins if the followed actor is the relay and the actor follower is an instance
  """
  @spec send_notification_to_admins(Follower.t()) :: :ok
  def send_notification_to_admins(
        %Follower{
          approved: false,
          actor: %Actor{type: :Application} = follower,
          target_actor: %Actor{id: target_actor_id}
        } = _follow
      ) do
    relay_actor = Relay.get_actor()

    if relay_actor.id == target_actor_id do
      Enum.each(Users.list_admins(), fn admin ->
        send_notification_to_admin(admin, follower)
      end)
    end

    :ok
  end

  def send_notification_to_admins(_), do: :ok

  defp send_notification_to_admin(
         %User{email: email, locale: locale},
         %Actor{type: follower_type} = follower
       ) do
    Gettext.put_locale(locale)

    subject =
      if follower_type == :Application do
        # Mastodon instance actor has no name and an username equal to the domain
        if is_nil(follower.name) and follower.preferred_username == follower.domain do
          gettext(
            "Instance %{domain} requests to follow your instance",
            domain: follower.domain
          )
        else
          gettext(
            "Instance %{name} (%{domain}) requests to follow your instance",
            name: follower.name || follower.preferred_username,
            domain: follower.domain
          )
        end
      else
        gettext(
          "%{name} requests to follow your instance",
          name: Actor.display_name_and_username(follower)
        )
      end

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:instance_follow, %{locale: locale, follower: follower, subject: subject})
    |> Email.Mailer.send_email()

    :ok
  end

  defp send_notification_to_admin(_, _), do: :ok
end
