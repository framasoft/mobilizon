defmodule Mobilizon.Service.Workers.RefreshParticipantStats do
  @moduledoc """
  Worker to refresh the participant event stats based on participants data
  """

  use Oban.Worker, unique: [period: :infinity, keys: [:event_uuid, :action]]

  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Storage.Page
  alias Oban.Job
  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Job{}) do
    refresh_participant_stats()
  end

  def refresh_participant_stats do
    Logger.info("Launching RefreshParticipantStats job")
    %Page{elements: future_events} = Events.list_events(1, 100_000_000)

    updated_events_count =
      Enum.reduce(future_events, 0, fn %Event{} = event, updated_events_count ->
        participants = Events.list_all_participants_for_event(event.id)

        participant_stats =
          Enum.reduce(
            participants,
            %{
              not_approved: 0,
              not_confirmed: 0,
              rejected: 0,
              participant: 0,
              moderator: 0,
              administrator: 0,
              creator: 0
            },
            fn %Participant{role: role}, acc ->
              Map.update(acc, role, 1, &(&1 + 1))
            end
          )

        if participant_stats != Map.from_struct(event.participant_stats) do
          Logger.debug("Uupdating event #{event.id} because of wrong participant_stats")

          Events.update_event(event, %{
            participant_stats: participant_stats
          })

          updated_events_count + 1
        else
          Logger.debug("Skipped updating event #{event.id}")
          updated_events_count
        end
      end)

    Logger.info("Updated #{updated_events_count} events on #{length(future_events)}")
  end
end
