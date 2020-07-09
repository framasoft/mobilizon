defmodule Mobilizon.Federation.ActivityPub.Types.Reports do
  @moduledoc false
  alias Mobilizon.{Actors, Discussions, Reports}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Reports.Report
  alias Mobilizon.Service.Formatter.HTML
  require Logger

  def flag(args, local \\ false, _additional \\ %{}) do
    with {:build_args, args} <- {:build_args, prepare_args_for_report(args)},
         {:create_report, {:ok, %Report{} = report}} <-
           {:create_report, Reports.create_report(args)},
         report_as_data <- Convertible.model_to_as(report),
         cc <- if(local, do: [report.reported.url], else: []),
         report_as_data <- Map.merge(report_as_data, %{"to" => [], "cc" => cc}) do
      {report, report_as_data}
    end
  end

  defp prepare_args_for_report(args) do
    with {:reporter, %Actor{} = reporter_actor} <-
           {:reporter, Actors.get_actor!(args.reporter_id)},
         {:reported, %Actor{} = reported_actor} <-
           {:reported, Actors.get_actor!(args.reported_id)},
         content <- HTML.strip_tags(args.content),
         event <- Discussions.get_comment(Map.get(args, :event_id)),
         {:get_report_comments, comments} <-
           {:get_report_comments,
            Discussions.list_comments_by_actor_and_ids(
              reported_actor.id,
              Map.get(args, :comments_ids, [])
            )} do
      Map.merge(args, %{
        reporter: reporter_actor,
        reported: reported_actor,
        content: content,
        event: event,
        comments: comments
      })
    end
  end
end
