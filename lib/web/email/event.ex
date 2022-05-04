defmodule Mobilizon.Web.Email.Event do
  @moduledoc """
  Handles emails sent about events.
  """

  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.JsonLD.ObjectView

  @important_changes [:title, :begins_on, :ends_on, :status, :physical_address]

  @spec event_updated(
          String.t(),
          Participant.t(),
          Actor.t(),
          Event.t(),
          Event.t(),
          MapSet.t(),
          String.t(),
          String.t()
        ) ::
          Swoosh.Email.t()
  def event_updated(
        email,
        %Participant{} = participant,
        %Actor{} = actor,
        %Event{} = old_event,
        %Event{} = event,
        changes,
        timezone,
        locale
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Event %{title} has been updated",
        title: old_event.title
      )

    json_ld =
      "participation.json"
      |> ObjectView.render(%{participant: %Participant{participant | event: event, actor: actor}})
      |> Jason.encode!()

    [to: {Actor.display_name(actor), email}, subject: subject]
    |> Email.base_email()
    |> Email.add_event_attachment(event)
    |> render_body(:event_updated, %{
      locale: locale,
      event: event,
      old_event: old_event,
      changes: changes,
      subject: subject,
      timezone: timezone,
      jsonLDMetadata: json_ld
    })
  end

  @spec calculate_event_diff_and_send_notifications(Event.t(), Event.t(), map()) :: {:ok, :ok}
  def calculate_event_diff_and_send_notifications(
        %Event{} = old_event,
        %Event{id: event_id} = event,
        changes
      ) do
    important = @important_changes |> Enum.map(&to_string/1) |> MapSet.new()

    diff =
      changes
      |> Map.keys()
      |> MapSet.new()
      |> MapSet.intersection(important)
      |> Enum.map(&String.to_existing_atom/1)
      |> MapSet.new()

    if MapSet.size(diff) > 0 do
      Repo.transaction(
        fn ->
          event_id
          |> Events.list_local_emails_user_participants_for_event_query()
          |> Repo.stream()
          |> Enum.to_list()
          |> Enum.each(
            &send_notification_for_event_update_to_participant(&1, old_event, event, diff)
          )
        end,
        timeout: 120_000
      )
    else
      {:ok, :ok}
    end
  end

  @spec send_notification_for_event_update_to_participant(
          {Participant.t(), Actor.t(), User.t() | nil, Setting.t() | nil},
          Event.t(),
          Event.t(),
          MapSet.t()
        ) :: Swoosh.Email.t()
  defp send_notification_for_event_update_to_participant(
         {%Participant{} = participant, %Actor{} = actor,
          %User{locale: locale, email: email} = _user, %Setting{timezone: timezone}},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    do_send_notification_for_event_update_to_participant(
      participant,
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
         {%Participant{} = participant, %Actor{} = actor,
          %User{locale: locale, email: email} = _user, nil},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    do_send_notification_for_event_update_to_participant(
      participant,
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
         {%Participant{metadata: %{email: email} = participant_metadata} = participant,
          %Actor{} = actor, nil, nil},
         %Event{} = old_event,
         %Event{} = event,
         diff
       )
       when not is_nil(email) do
    locale = Gettext.get_locale()

    do_send_notification_for_event_update_to_participant(
      participant,
      email,
      actor,
      old_event,
      event,
      diff,
      Map.get(participant_metadata, :timezone, "Etc/UTC"),
      locale
    )
  end

  @spec do_send_notification_for_event_update_to_participant(
          Participant.t(),
          String.t(),
          Actor.t(),
          Event.t(),
          Event.t(),
          MapSet.t(),
          String.t(),
          String.t()
        ) :: Swoosh.Email.t()
  defp do_send_notification_for_event_update_to_participant(
         participant,
         email,
         actor,
         old_event,
         event,
         diff,
         timezone,
         locale
       ) do
    email
    |> event_updated(participant, actor, old_event, event, diff, timezone, locale)
    |> Email.Mailer.send_email()
  end
end
