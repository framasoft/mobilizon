defmodule Mobilizon.GraphQL.API.Reports do
  @moduledoc """
  API for Reports.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Admin, Users}
  alias Mobilizon.Reports, as: ReportsAction
  alias Mobilizon.Reports.{Note, Report, ReportStatus}
  alias Mobilizon.Users.User

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity

  @doc """
  Create a report/flag on an actor, and optionally on an event or on comments.
  """
  def report(args) do
    case {:make_activity, ActivityPub.flag(args, Map.get(args, :forward, false) == true)} do
      {:make_activity, {:ok, %Activity{} = activity, %Report{} = report}} ->
        {:ok, activity, report}

      {:make_activity, err} ->
        {:error, err}
    end
  end

  @doc """
  Update the state of a report
  """
  def update_report_status(%Actor{} = actor, %Report{} = report, state) do
    with {:valid_state, true} <-
           {:valid_state, ReportStatus.valid_value?(state)},
         {:ok, report} <- ReportsAction.update_report(report, %{"status" => state}),
         {:ok, _} <- Admin.log_action(actor, "update", report) do
      {:ok, report}
    else
      {:valid_state, false} -> {:error, "Unsupported state"}
    end
  end

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
           Mobilizon.Reports.create_note(%{
             "report_id" => report_id,
             "moderator_id" => moderator_id,
             "content" => content
           }),
         {:ok, _} <- Admin.log_action(moderator, "create", note) do
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
           Mobilizon.Reports.delete_note(note),
         {:ok, _} <- Admin.log_action(moderator, "delete", note) do
      {:ok, note}
    else
      {:role, false} ->
        {:error, "You need to be a moderator or an administrator to create a note on a report"}

      {:same_actor, false} ->
        {:error, "You can only remove your own notes"}
    end
  end
end
