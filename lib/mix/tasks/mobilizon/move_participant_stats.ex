defmodule Mix.Tasks.Mobilizon.MoveParticipantStats do
  @moduledoc """
  Temporary task to move participant stats in the events table

  This task will be removed in version 1.0.0-beta.3
  """

  use Mix.Task

  import Ecto.Query

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Events.ParticipantRole
  alias Mobilizon.Storage.Repo

  require Logger

  @shortdoc "Move participant stats to events table"
  def run([]) do
    Mix.Task.run("app.start")

    events =
      Event
      |> preload([e], :tags)
      |> Repo.all()

    nb_events = length(events)

    IO.puts(
      "\nStarting inserting participants stats into #{nb_events} events, this can take a while…\n"
    )

    insert_participants_stats_into_events(events, nb_events)
  end

  defp insert_participants_stats_into_events([%Event{url: url} = event | events], nb_events) do
    with roles <- ParticipantRole.__enum_map__(),
         counts <-
           Enum.reduce(roles, %{}, fn role, acc ->
             Map.put(acc, role, count_participants(event, role))
           end),
         {:ok, _} <-
           Events.update_event(event, %{
             participant_stats: counts
           }) do
      Logger.debug("Added participants stats to event #{url}")
    else
      {:error, res} ->
        Logger.error("Error while adding participants stats to event #{url} : #{inspect(res)}")
    end

    ProgressBar.render(nb_events - length(events), nb_events)

    insert_participants_stats_into_events(events, nb_events)
  end

  defp insert_participants_stats_into_events([], nb_events) do
    IO.puts("\nFinished inserting participant stats for #{nb_events} events!\n")
  end

  defp count_participants(%Event{id: event_id}, role) when is_atom(role) do
    event_id
    |> Events.count_participants_query()
    |> Events.filter_role(role)
    |> Repo.aggregate(:count, :id)
  end
end
