defmodule Mobilizon.Web.Email.Event do
  @moduledoc """
  Handles emails sent about events.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User

  alias Mobilizon.Web.{Gettext, Email}

  @important_changes [:title, :begins_on, :ends_on, :status]

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
    Gettext.put_locale(locale)

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

  def calculate_event_diff_and_send_notifications(
        %Event{} = old_event,
        %Event{id: event_id} = event,
        changes
      ) do
    important = MapSet.new(@important_changes)

    diff =
      changes
      |> Map.keys()
      |> MapSet.new()
      |> MapSet.intersection(important)

    if MapSet.size(diff) > 0 do
      Repo.transaction(fn ->
        event_id
        |> Events.list_local_emails_user_participants_for_event_query()
        |> Repo.stream()
        |> Enum.to_list()
        |> Enum.each(
          &send_notification_for_event_update_to_participant(&1, old_event, event, diff)
        )
      end)
    end
  end

  defp send_notification_for_event_update_to_participant(
         {%Actor{} = actor, %User{locale: locale} = user},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    user
    |> Email.Event.event_updated(actor, old_event, event, diff, locale)
    |> Email.Mailer.deliver_later()
  end
end
