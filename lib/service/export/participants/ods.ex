defmodule Mobilizon.Service.Export.Participants.ODS do
  @moduledoc """
  Export a list of participants to ODS
  """

  alias Mobilizon.{Events, Export, PythonPort, PythonWorker}
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Web.Gettext, as: GettextBackend
  import Mobilizon.Web.Gettext, only: [gettext: 2]

  import Mobilizon.Service.Export.Participants.Common,
    only: [
      save_upload: 5,
      to_list: 1,
      clean_exports: 2,
      columns: 0,
      export_enabled?: 1,
      export_path: 1
    ]

  @extension "ods"

  def extension do
    @extension
  end

  @spec export(Event.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, :failed_to_save_upload | :export_dependency_not_installed}
  def export(%Event{id: event_id} = event, options \\ []) do
    if ready?() do
      filename = "#{ShortUUID.encode!(Ecto.UUID.generate())}.ods"
      full_path = Path.join([export_path(@extension), filename])

      case Repo.transaction(
             fn ->
               content =
                 event_id
                 |> Events.participant_for_event_export_query(Keyword.get(options, :roles, []))
                 |> Repo.all()
                 |> Enum.map(&to_list/1)
                 |> add_header_columns()
                 |> generate_ods()

               File.write!(full_path, content)

               with {:error, err} <- save_ods_upload(full_path, filename, event) do
                 Repo.rollback(err)
               end
             end,
             timeout: :infinity
           ) do
        {:error, _err} ->
          File.rm!(full_path)
          {:error, :failed_to_save_upload}

        {:ok, _ok} ->
          {:ok, filename}
      end
    else
      {:error, :export_dependency_not_installed}
    end
  end

  defp add_header_columns(data) do
    Enum.concat([columns()], data)
  end

  defp generate_ods(data) do
    data
    |> Jason.encode!()
    |> PythonWorker.generate_ods()
  end

  @spec save_ods_upload(String.t(), String.t(), Event.t()) ::
          {:ok, Export.t()} | {:error, atom() | Ecto.Changeset.t()}
  defp save_ods_upload(full_path, filename, %Event{id: event_id, title: title}) do
    GettextBackend.gettext_comment(
      "File name template for exported list of participants. Should NOT contain spaces. Make sure the output is going to be something standardized that is acceptable as a file name on most systems."
    )

    save_upload(
      full_path,
      filename,
      to_string(event_id),
      gettext("%{event}_participants", event: title) <> ".ods",
      "ods"
    )
  end

  @doc """
  Clean outdated files in export folder
  """
  @spec clean_exports :: :ok
  def clean_exports do
    clean_exports(@extension, export_path(@extension))
  end

  @spec dependencies_ok? :: boolean
  def dependencies_ok? do
    PythonPort.python_exists?() && PythonWorker.has_module("pyexcel_ods3")
  end

  @spec enabled? :: boolean
  def enabled? do
    export_enabled?(__MODULE__)
  end

  @spec ready? :: boolean
  def ready? do
    enabled?() && dependencies_ok?()
  end
end
