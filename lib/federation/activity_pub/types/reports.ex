defmodule Mobilizon.Federation.ActivityPub.Types.Reports do
  @moduledoc false
  alias Mobilizon.{Actors, Discussions, Events, Reports}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Reports.Report
  alias Mobilizon.Service.Formatter.HTML
  require Logger

  @spec flag(map(), boolean(), map()) ::
          {:ok, Report.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def flag(args, local \\ false, _additional \\ %{}) do
    with {:ok, %Report{} = report} <- args |> prepare_args_for_report() |> Reports.create_report() do
      report_as_data = Convertible.model_to_as(report)
      cc = if(local, do: [report.reported.url], else: [])
      report_as_data = Map.merge(report_as_data, %{"to" => [], "cc" => cc})
      {:ok, report, report_as_data}
    end
  end

  @spec prepare_args_for_report(map()) :: map()
  defp prepare_args_for_report(args) do
    %Actor{} = reporter_actor = Actors.get_actor!(args.reporter_id)
    %Actor{} = reported_actor = Actors.get_actor!(args.reported_id)
    content = HTML.strip_tags(args.content)

    event_id = Map.get(args, :event_id)

    event =
      if is_nil(event_id) do
        nil
      else
        {:ok, %Event{} = event} = Events.get_event(event_id)
        event
      end

    comments =
      Discussions.list_comments_by_actor_and_ids(
        reported_actor.id,
        Map.get(args, :comments_ids, [])
      )

    Map.merge(args, %{
      reporter: reporter_actor,
      reported: reported_actor,
      content: content,
      event: event,
      comments: comments
    })
  end
end
