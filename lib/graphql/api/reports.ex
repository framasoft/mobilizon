defmodule Mobilizon.GraphQL.API.Reports do
  @moduledoc """
  API for Reports.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Admin, Users}
  alias Mobilizon.Reports, as: ReportsAction
  alias Mobilizon.Reports.{Note, Report, ReportStatus}
  alias Mobilizon.Users.User

  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}

  @doc """
  Create a report/flag on an actor, and optionally on an event or on comments.
  """
  @spec report(map()) :: {:ok, Activity.t(), Report.t()} | {:error, Ecto.Changeset.t()}
  def report(args) do
    Actions.Flag.flag(args, Map.get(args, :forward, false) == true)
  end

  @doc """
  Update the state of a report
  """
  @spec update_report_status(Actor.t(), Report.t(), ReportStatus.t()) ::
          {:ok, Report.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def update_report_status(%Actor{} = actor, %Report{} = report, state) do
    if ReportStatus.valid_value?(state) do
      with {:ok, %Report{} = report} <- ReportsAction.update_report(report, %{"status" => state}) do
        Admin.log_action(actor, "update", report)
        {:ok, report}
      end
    else
      {:error, "Unsupported state"}
    end
  end

  @doc """
  Create a note on a report
  """
  @spec create_report_note(Report.t(), Actor.t(), String.t()) ::
          {:ok, Note.t()} | {:error, String.t() | Ecto.Changeset.t()}
  def create_report_note(
        %Report{id: report_id},
        %Actor{id: moderator_id, user_id: user_id} = moderator,
        content
      ) do
    %User{role: role} = Users.get_user!(user_id)

    if role in [:administrator, :moderator] do
      with {:ok, %Note{} = note} <-
             Mobilizon.Reports.create_note(%{
               "report_id" => report_id,
               "moderator_id" => moderator_id,
               "content" => content
             }),
           {:ok, _} <- Admin.log_action(moderator, "create", note) do
        {:ok, note}
      end
    else
      {:error, "You need to be a moderator or an administrator to create a note on a report"}
    end
  end

  @doc """
  Delete a report note
  """
  @spec delete_report_note(Note.t(), Actor.t()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def delete_report_note(
        %Note{moderator_id: note_moderator_id} = note,
        %Actor{id: moderator_id, user_id: user_id} = moderator
      ) do
    if note_moderator_id == moderator_id do
      %User{role: role} = Users.get_user!(user_id)

      if role in [:administrator, :moderator] do
        with {:ok, %Note{} = note} <-
               Mobilizon.Reports.delete_note(note),
             {:ok, _} <- Admin.log_action(moderator, "delete", note) do
          {:ok, note}
        end
      else
        {:error, "You need to be a moderator or an administrator to create a note on a report"}
      end
    else
      {:error, "You can only remove your own notes"}
    end
  end
end
