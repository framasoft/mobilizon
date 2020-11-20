defmodule Mobilizon.GraphQL.Resolvers.Report do
  @moduledoc """
  Handles the report-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Config, Reports, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.GraphQL.API

  def list_reports(
        _parent,
        %{page: page, limit: limit, status: status},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    {:ok, Mobilizon.Reports.list_reports(page, limit, :updated_at, :desc, status)}
  end

  def list_reports(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to list reports")}
  end

  def get_report(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_moderator(role) do
    case Mobilizon.Reports.get_report(id) do
      %Report{} = report ->
        {:ok, report}

      nil ->
        {:error, dgettext("errors", "Report not found")}
    end
  end

  def get_report(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to view a report")}
  end

  @doc """
  Create a report, either logged-in or anonymously
  """
  def create_report(
        _parent,
        args,
        %{context: %{current_user: %User{} = user}} = _resolution
      ) do
    with %Actor{id: reporter_id} <- Users.get_actor_for_user(user),
         {:ok, _, %Report{} = report} <-
           args |> Map.put(:reporter_id, reporter_id) |> API.Reports.report() do
      {:ok, report}
    else
      _error ->
        {:error, dgettext("errors", "Error while saving report")}
    end
  end

  def create_report(
        _parent,
        args,
        _resolution
      ) do
    with {:anonymous_reporting_allowed, true} <-
           {:anonymous_reporting_allowed, Config.anonymous_reporting?()},
         {:ok, _, %Report{} = report} <-
           args |> Map.put(:reporter_id, Config.anonymous_actor_id()) |> API.Reports.report() do
      {:ok, report}
    else
      {:anonymous_reporting_allowed, _} ->
        {:error, dgettext("errors", "You need to be logged-in to create reports")}

      _error ->
        {:error, dgettext("errors", "Error while saving report")}
    end
  end

  @doc """
  Update a report's status
  """
  def update_report(
        _parent,
        %{report_id: report_id, status: status},
        %{context: %{current_user: %User{role: role} = user}}
      )
      when is_moderator(role) do
    with %Actor{} = actor <- Users.get_actor_for_user(user),
         %Report{} = report <- Mobilizon.Reports.get_report(report_id),
         {:ok, %Report{} = report} <- API.Reports.update_report_status(actor, report, status) do
      {:ok, report}
    else
      _error ->
        {:error, dgettext("errors", "Error while updating report")}
    end
  end

  def update_report(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to update a report")}
  end

  def create_report_note(
        _parent,
        %{report_id: report_id, content: content},
        %{context: %{current_user: %User{role: role} = user}}
      )
      when is_moderator(role) do
    with %Actor{id: moderator_id} <- Users.get_actor_for_user(user),
         %Report{} = report <- Reports.get_report(report_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_preload(moderator_id),
         {:ok, %Note{} = note} <- API.Reports.create_report_note(report, moderator, content) do
      {:ok, note}
    end
  end

  def delete_report_note(
        _parent,
        %{note_id: note_id},
        %{context: %{current_user: %User{role: role} = user}}
      )
      when is_moderator(role) do
    with %Actor{id: moderator_id} <- Users.get_actor_for_user(user),
         %Note{} = note <- Reports.get_note(note_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_preload(moderator_id),
         {:ok, %Note{} = note} <- API.Reports.delete_report_note(note, moderator) do
      {:ok, %{id: note.id}}
    end
  end
end
