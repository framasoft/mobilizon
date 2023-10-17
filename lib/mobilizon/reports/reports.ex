defmodule Mobilizon.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Storage.{Page, Repo}

  defenum(ReportStatus, :report_status, [:open, :closed, :resolved])

  @doc """
  Gets a single report.
  """
  @spec get_report(integer | String.t()) :: Report.t() | nil
  def get_report(id) do
    Report
    |> Repo.get(id)
    |> Repo.preload([
      :reported,
      :reporter,
      :manager,
      :events,
      :notes,
      comments: [conversation: [:participants]]
    ])
  end

  @doc """
  Creates a report.
  """
  @spec create_report(map) :: {:ok, Report.t()} | {:error, Ecto.Changeset.t()}
  def create_report(attrs \\ %{}) do
    with {:ok, %Report{} = report} <-
           %Report{}
           |> Report.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(report, [:events, :reported, :reporter, :comments])}
    end
  end

  @doc """
  Updates a report.
  """
  @spec update_report(Report.t(), map) :: {:ok, Report.t()} | {:error, Ecto.Changeset.t()}
  def update_report(%Report{} = report, attrs) do
    report
    |> Report.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns the list of reports.
  """
  @spec list_reports(Keyword.t()) :: Page.t(Report.t())
  def list_reports(options) do
    page = Keyword.get(options, :page)
    limit = Keyword.get(options, :limit)
    sort = Keyword.get(options, :sort, :updated_at)
    direction = Keyword.get(options, :direction, :asc)
    status = Keyword.get(options, :status, :open)
    domain = Keyword.get(options, :domain)

    status
    |> list_reports_query()
    |> filter_domain_name(domain)
    |> sort(sort, direction)
    |> Page.build_page(page, limit)
  end

  @doc """
  Counts opened reports.
  """
  @spec count_opened_reports :: integer
  def count_opened_reports do
    Repo.aggregate(count_reports_query(), :count, :id)
  end

  @doc """
  Gets a single note.
  """
  @spec get_note(integer | String.t()) :: Note.t() | nil
  def get_note(id), do: Repo.get(Note, id)

  @doc """
  Creates a note.
  """
  @spec create_note(map) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def create_note(attrs \\ %{}) do
    with {:ok, %Note{} = note} <-
           %Note{}
           |> Note.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(note, [:report, :moderator])}
    end
  end

  @doc """
  Deletes a note.
  """
  @spec delete_note(Note.t()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def delete_note(%Note{} = note), do: Repo.delete(note)

  @spec list_reports_query(atom()) :: Ecto.Query.t()
  defp list_reports_query(status) do
    Report
    |> preload([:reported, :reporter, :manager, :events, :comments, :notes])
    |> where([r], r.status == ^status)
  end

  @spec filter_domain_name(Ecto.Queryable.t(), String.t() | nil) :: Ecto.Queryable.t()
  defp filter_domain_name(query, nil), do: query
  defp filter_domain_name(query, ""), do: query

  defp filter_domain_name(query, domain) do
    query
    |> join(:inner, [r], a in Actor, on: a.id == r.reported_id)
    |> where([_r, a], like(a.domain, ^"%#{domain}%"))
  end

  @spec count_reports_query :: Ecto.Query.t()
  defp count_reports_query do
    from(r in Report, where: r.status == ^:open)
  end
end
