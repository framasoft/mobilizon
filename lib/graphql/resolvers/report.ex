defmodule Mobilizon.GraphQL.Resolvers.Report do
  @moduledoc """
  Handles the report-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Config, Reports}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.GraphQL.API

  @spec list_reports(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Report.t())} | {:error, String.t()}
  def list_reports(
        _parent,
        %{page: page, limit: limit} = args,
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    {:ok,
     Mobilizon.Reports.list_reports(
       page: page,
       limit: limit,
       sort: :updated_at,
       direction: :desc,
       status: Map.get(args, :status),
       domain: Map.get(args, :domain)
     )}
  end

  def list_reports(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to list reports")}
  end

  @spec get_report(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Report.t()} | {:error, String.t()}
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
  @spec create_report(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Report.t()} | {:error, String.t()}
  def create_report(
        _parent,
        args,
        %{context: %{current_actor: %Actor{id: reporter_id}}} = _resolution
      ) do
    case args |> Map.put(:reporter_id, reporter_id) |> API.Reports.report() do
      {:ok, _, %Report{} = report} ->
        {:ok, report}

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
  @spec update_report(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Report.t()} | {:error, String.t()}
  def update_report(
        _parent,
        %{report_id: report_id, status: status} = args,
        %{context: %{current_user: %User{role: role}, current_actor: %Actor{} = actor}}
      )
      when is_moderator(role) do
    with %Report{} = report <- Mobilizon.Reports.get_report(report_id),
         {:ok, %Report{} = report} <-
           API.Reports.update_report_status(
             actor,
             report,
             status,
             Map.get(args, :antispam_feedback)
           ) do
      {:ok, report}
    else
      _error ->
        {:error, dgettext("errors", "Error while updating report")}
    end
  end

  def update_report(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to update a report")}
  end

  @spec create_report_note(any(), map(), Absinthe.Resolution.t()) :: {:ok, Note.t()}
  def create_report_note(
        _parent,
        %{report_id: report_id, content: content},
        %{context: %{current_user: %User{role: role}, current_actor: %Actor{id: moderator_id}}}
      )
      when is_moderator(role) do
    with %Report{} = report <- Reports.get_report(report_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_preload(moderator_id),
         {:ok, %Note{} = note} <- API.Reports.create_report_note(report, moderator, content) do
      {:ok, note}
    end
  end

  @spec delete_report_note(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()}
  def delete_report_note(
        _parent,
        %{note_id: note_id},
        %{context: %{current_user: %User{role: role}, current_actor: %Actor{id: moderator_id}}}
      )
      when is_moderator(role) do
    with %Note{} = note <- Reports.get_note(note_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_preload(moderator_id),
         {:ok, %Note{} = note} <- API.Reports.delete_report_note(note, moderator) do
      {:ok, %{id: note.id}}
    end
  end
end
