defmodule MobilizonWeb.API.Reports do
  @moduledoc """
  API for Reports
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Activity
  alias Mobilizon.Reports, as: ReportsAction
  alias Mobilizon.Reports.{Report, Note}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import MobilizonWeb.API.Utils
  import Mobilizon.Service.Admin.ActionLogService

  @doc """
  Create a report/flag on an actor, and optionally on an event or on comments.
  """
  def report(
        %{
          reporter_actor_id: reporter_actor_id,
          reported_actor_id: reported_actor_id,
          event_id: event_id,
          comments_ids: comments_ids,
          report_content: report_content
        } = args
      ) do
    with {:reporter, %Actor{url: reporter_url} = _reporter_actor} <-
           {:reporter, Actors.get_actor!(reporter_actor_id)},
         {:reported, %Actor{url: reported_actor_url} = reported_actor} <-
           {:reported, Actors.get_actor!(reported_actor_id)},
         {:ok, content} <- make_report_content_html(report_content),
         {:ok, event} <-
           if(event_id, do: Events.get_event(event_id), else: {:ok, nil}),
         {:get_report_comments, comments_urls} <-
           get_report_comments(reported_actor, comments_ids),
         {:make_activity, {:ok, %Activity{} = activity, %Report{} = report}} <-
           {:make_activity,
            ActivityPub.flag(%{
              reporter_url: reporter_url,
              reported_actor_url: reported_actor_url,
              event_url: (!is_nil(event) && event.url) || nil,
              comments_url: comments_urls,
              content: content,
              forward: args[:forward] || false,
              local: args[:local] || args[:forward] || false
            })} do
      {:ok, activity, report}
    else
      {:error, err} -> {:error, err}
      {:actor_id, %{}} -> {:error, "Valid `actor_id` required"}
      {:reporter, nil} -> {:error, "Reporter Actor not found"}
      {:reported, nil} -> {:error, "Reported Actor not found"}
    end
  end

  @doc """
  Update the state of a report
  """
  def update_report_status(%Actor{} = actor, %Report{} = report, state) do
    with {:valid_state, true} <-
           {:valid_state, Mobilizon.Reports.ReportStateEnum.valid_value?(state)},
         {:ok, report} <- ReportsAction.update_report(report, %{"status" => state}),
         {:ok, _} <- log_action(actor, "update", report) do
      {:ok, report}
    else
      {:valid_state, false} -> {:error, "Unsupported state"}
    end
  end

  defp get_report_comments(%Actor{id: actor_id}, comment_ids) do
    {:get_report_comments,
     Events.get_all_comments_by_actor_and_ids(actor_id, comment_ids) |> Enum.map(& &1.url)}
  end

  defp get_report_comments(_, _), do: {:get_report_comments, nil}

  @doc """
  Create a note on a report
  """
  @spec create_report_note(Report.t(), Actor.t(), String.t()) :: {:ok, Note.t()}
  def create_report_note(
        %Report{id: report_id},
        %Actor{id: moderator_id, user_id: user_id} = moderator,
        content
      ) do
    with %User{role: role} <- Users.get_user!(user_id),
         {:role, true} <- {:role, role in [:administrator, :moderator]},
         {:ok, %Note{} = note} <-
           Mobilizon.Reports.create_report_note(%{
             "report_id" => report_id,
             "moderator_id" => moderator_id,
             "content" => content
           }),
         {:ok, _} <- log_action(moderator, "create", note) do
      {:ok, note}
    else
      {:role, false} ->
        {:error, "You need to be a moderator or an administrator to create a note on a report"}
    end
  end

  @doc """
  Delete a report note
  """
  @spec delete_report_note(Note.t(), Actor.t()) :: {:ok, Note.t()}
  def delete_report_note(
        %Note{moderator_id: note_moderator_id} = note,
        %Actor{id: moderator_id, user_id: user_id} = moderator
      ) do
    with {:same_actor, true} <- {:same_actor, note_moderator_id == moderator_id},
         %User{role: role} <- Users.get_user!(user_id),
         {:role, true} <- {:role, role in [:administrator, :moderator]},
         {:ok, %Note{} = note} <-
           Mobilizon.Reports.delete_report_note(note),
         {:ok, _} <- log_action(moderator, "delete", note) do
      {:ok, note}
    else
      {:role, false} ->
        {:error, "You need to be a moderator or an administrator to create a note on a report"}

      {:same_actor, false} ->
        {:error, "You can only remove your own notes"}
    end
  end
end
