defmodule Mobilizon.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

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
    |> Repo.preload([:reported, :reporter, :manager, :event, :comments, :notes])
  end

  @doc """
  Gets a single report.
  Raises `Ecto.NoResultsError` if the report does not exist.
  """
  @spec get_report!(integer | String.t()) :: Report.t()
  def get_report!(id) do
    Report
    |> Repo.get!(id)
    |> Repo.preload([:reported, :reporter, :manager, :event, :comments, :notes])
  end

  @doc """
  Get a report by its URL
  """
  @spec get_report_by_url(String.t()) :: Report.t() | nil
  def get_report_by_url(url) do
    url
    |> report_by_url_query()
    |> Repo.one()
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
      {:ok, Repo.preload(report, [:event, :reported, :reporter, :comments])}
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
  Deletes a report.
  """
  @spec delete_report(Report.t()) :: {:ok, Report.t()} | {:error, Ecto.Changeset.t()}
  def delete_report(%Report{} = report), do: Repo.delete(report)

  @doc """
  Returns the list of reports.
  """
  @spec list_reports(integer | nil, integer | nil, atom, atom, ReportStatus) :: [Report.t()]
  def list_reports(
        page \\ nil,
        limit \\ nil,
        sort \\ :updated_at,
        direction \\ :asc,
        status \\ :open
      ) do
    status
    |> list_reports_query()
    |> Page.paginate(page, limit)
    |> sort(sort, direction)
    |> Repo.all()
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
  Gets a single note.
  Raises `Ecto.NoResultsError` if the Note does not exist.
  """
  @spec get_note!(integer | String.t()) :: Note.t()
  def get_note!(id), do: Repo.get!(Note, id)

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

  @doc """
  Returns the list of notes for a report.
  """
  @spec list_notes_for_report(Report.t()) :: [Note.t()]
  def list_notes_for_report(%Report{id: report_id}) do
    report_id
    |> list_notes_for_report_query()
    |> Repo.all()
  end

  @spec report_by_url_query(String.t()) :: Ecto.Query.t()
  defp report_by_url_query(url) do
    from(r in Report, where: r.uri == ^url)
  end

  @spec list_reports_query(ReportStatus.t()) :: Ecto.Query.t()
  defp list_reports_query(status) do
    from(
      r in Report,
      preload: [:reported, :reporter, :manager, :event, :comments, :notes],
      where: r.status == ^status
    )
  end

  @spec count_reports_query :: Ecto.Query.t()
  defp count_reports_query do
    from(r in Report, where: r.status == ^:open)
  end

  @spec list_notes_for_report_query(integer | String.t()) :: Ecto.Query.t()
  defp list_notes_for_report_query(report_id) do
    from(
      n in Note,
      where: n.report_id == ^report_id,
      preload: [:report, :moderator]
    )
  end
end
