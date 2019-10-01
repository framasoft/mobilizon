defmodule MobilizonWeb.Email.Event do
  @moduledoc """
  Handles emails sent about events.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  import Bamboo.Phoenix

  import MobilizonWeb.Gettext

  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  alias MobilizonWeb.Email

  @spec event_updated(User.t(), Actor.t(), Event.t(), Event.t(), list(), String.t()) ::
          Bamboo.Email.t()
  def event_updated(
        %User{} = user,
        %Actor{} = actor,
        %Event{} = old_event,
        %Event{} = event,
        changes,
        locale \\ "en"
      ) do
    MobilizonWeb.Gettext.put_locale(locale)

    subject =
      gettext(
        "Event %{title} has been updated",
        title: old_event.title
      )

    Email.base_email(to: {Actor.display_name(actor), user.email}, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:old_event, old_event)
    |> assign(:changes, changes)
    |> assign(:subject, subject)
    |> render(:event_updated)
  end
end
