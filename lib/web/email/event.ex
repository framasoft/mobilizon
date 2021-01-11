defmodule Mobilizon.Web.Email.Event do
  @moduledoc """
  Handles emails sent about events.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.{Setting, User}

  alias Mobilizon.Web.Email
  alias Mobilizon.Web.Gettext, as: GettextBackend

  @important_changes [:title, :begins_on, :ends_on, :status, :physical_address]

  @spec event_updated(String.t(), Actor.t(), Event.t(), Event.t(), MapSet.t(), String.t()) ::
          Bamboo.Email.t()
  def event_updated(
        email,
        %Actor{} = actor,
        %Event{} = old_event,
        %Event{} = event,
        changes,
        timezone \\ "Etc/UTC",
        locale \\ "en"
      ) do
    GettextBackend.put_locale(locale)

    subject =
      gettext(
        "Event %{title} has been updated",
        title: old_event.title
      )

    Email.base_email(to: {Actor.display_name(actor), email}, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:old_event, old_event)
    |> assign(:changes, changes)
    |> assign(:subject, subject)
    |> assign(:timezone, timezone)
    |> Email.add_event_attachment(event)
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
         {%Participant{} = _participant, %Actor{} = actor,
          %User{locale: locale, email: email} = _user, %Setting{timezone: timezone}},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    do_send_notification_for_event_update_to_participant(
      email,
      actor,
      old_event,
      event,
      diff,
      timezone,
      locale
    )
  end

  defp send_notification_for_event_update_to_participant(
         {%Participant{} = _participant, %Actor{} = actor,
          %User{locale: locale, email: email} = _user, nil},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    do_send_notification_for_event_update_to_participant(
      email,
      actor,
      old_event,
      event,
      diff,
      "Etc/UTC",
      locale
    )
  end

  defp send_notification_for_event_update_to_participant(
         {%Participant{metadata: %{email: email}} = _participant, %Actor{} = actor, nil, nil},
         %Event{} = old_event,
         %Event{} = event,
         diff
       )
       when not is_nil(email) do
    locale = Gettext.get_locale()

    do_send_notification_for_event_update_to_participant(
      email,
      actor,
      old_event,
      event,
      diff,
      "Etc/UTC",
      locale
    )
  end

  defp do_send_notification_for_event_update_to_participant(
         email,
         actor,
         old_event,
         event,
         diff,
         timezone,
         locale
       ) do
    email
    |> Email.Event.event_updated(actor, old_event, event, diff, timezone, locale)
    |> Email.Mailer.deliver_later()
  end
end
