defmodule Mobilizon.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false
  alias Mobilizon.Repo
  import Mobilizon.Ecto

  alias Mobilizon.Reports.Report
  alias Mobilizon.Reports.Note

  @doc false
  def data() do
    Dataloader.Ecto.new(Mobilizon.Repo, query: &query/2)
  end

  @doc false
  def query(queryable, _params) do
    queryable
  end

  @doc """
  Returns the list of reports.

  ## Examples

      iex> list_reports()
      [%Report{}, ...]

  """
  @spec list_reports(integer(), integer(), atom(), atom()) :: list(Report.t())
  def list_reports(page \\ nil, limit \\ nil, sort \\ :updated_at, direction \\ :asc) do
    from(
      r in Report,
      preload: [:reported, :reporter, :manager, :event, :comments, :notes]
    )
    |> paginate(page, limit)
    |> sort(sort, direction)
    |> Repo.all()
  end

  @doc """
  Gets a single report.

  Raises `Ecto.NoResultsError` if the Report does not exist.

  ## Examples

      iex> get_report!(123)
      %Report{}

      iex> get_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_report!(id) do
    with %Report{} = report <- Repo.get!(Report, id) do
      Repo.preload(report, [:reported, :reporter, :manager, :event, :comments, :notes])
    end
  end

  @doc """
  Gets a single report.

  Returns `nil` if the Report does not exist.

  ## Examples

      iex> get_report(123)
      %Report{}

      iex> get_report(456)
      nil

  """
  def get_report(id) do
    with %Report{} = report <- Repo.get(Report, id) do
      Repo.preload(report, [:reported, :reporter, :manager, :event, :comments, :notes])
    end
  end

  @doc """
  Get a report by it's URL
  """
  @spec get_report_by_url(String.t()) :: Report.t() | nil
  def get_report_by_url(url) do
    from(
      r in Report,
      where: r.uri == ^url
    )
    |> Repo.one()
  end

  @doc """
  Creates a report.

  ## Examples

      iex> create_report(%{field: value})
      {:ok, %Report{}}

      iex> create_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report(attrs \\ %{}) do
    with {:ok, %Report{} = report} <-
           %Report{}
           |> Report.creation_changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(report, [:event, :reported, :reporter, :comments])}
    end
  end

  @doc """
  Updates a report.

  ## Examples

      iex> update_report(report, %{field: new_value})
      {:ok, %Report{}}

      iex> update_report(report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report(%Report{} = report, attrs) do
    report
    |> Report.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Report.

  ## Examples

      iex> delete_report(report)
      {:ok, %Report{}}

      iex> delete_report(report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report(%Report{} = report) do
    Repo.delete(report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report changes.

  ## Examples

      iex> change_report(report)
      %Ecto.Changeset{source: %Report{}}

  """
  def change_report(%Report{} = report) do
    Report.changeset(report, %{})
  end

  @doc """
  Returns the list of notes for a report.

  ## Examples

      iex> list_notes_for_report(%Report{id: 1})
      [%Note{}, ...]

  """
  @spec list_notes_for_report(Report.t()) :: list(Report.t())
  def list_notes_for_report(%Report{id: report_id}) do
    from(
      n in Note,
      where: n.report_id == ^report_id,
      preload: [:report, :moderator]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id), do: Repo.get!(Note, id)

  def get_note(id), do: Repo.get(Note, id)

  @doc """
  Creates a note report.

  ## Examples

      iex> create_report_note(%{field: value})
      {:ok, %Note{}}

      iex> create_report_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report_note(attrs \\ %{}) do
    with {:ok, %Note{} = note} <-
           %Note{}
           |> Note.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(note, [:report, :moderator])}
    end
  end

  @doc """
  Deletes a note report.

  ## Examples

      iex> delete_report_note(note)
      {:ok, %Note{}}

      iex> delete_report_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report_note(%Note{} = note) do
    Repo.delete(note)
  end
end
