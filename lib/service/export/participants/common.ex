defmodule Mobilizon.Service.Export.Participants.Common do
  @moduledoc """
  Common functions for managing participants export
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Config, Export}
  alias Mobilizon.Events.Participant
  alias Mobilizon.Events.Participant.Metadata
  alias Mobilizon.Storage.Repo
  import Mobilizon.Web.Gettext, only: [gettext: 1]
  import Mobilizon.Service.DateTime, only: [datetime_to_string: 2]

  @spec save_upload(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, Export.t()} | {:error, atom() | Ecto.Changeset.t()}
  def save_upload(full_path, file_path, reference, file_name, format) do
    with {:ok, %File.Stat{size: file_size}} <- File.stat(full_path) do
      %Export{}
      |> Export.changeset(%{
        file_size: file_size,
        file_name: file_name,
        file_path: file_path,
        format: format,
        reference: reference,
        type: "event_participants"
      })
      |> Repo.insert()
    end
  end

  @doc """
  Match a participant role to it's translated version
  """
  @spec translate_role(atom()) :: String.t()
  def translate_role(role) do
    case role do
      :not_approved ->
        gettext("Not approved")

      :not_confirmed ->
        gettext("Not confirmed")

      :rejected ->
        gettext("Rejected")

      :participant ->
        gettext("Participant")

      :moderator ->
        gettext("Moderator")

      :administrator ->
        gettext("Administrator")

      :creator ->
        gettext("Creator")
    end
  end

  @spec columns :: list(String.t())
  def columns do
    [
      gettext("Participant name"),
      gettext("Participant status"),
      gettext("Participant registration date"),
      gettext("Participant message")
    ]
  end

  # One hour
  @expiration 60 * 60

  @doc """
  Clean outdated files in export folder
  """
  @spec clean_exports(String.t(), String.t(), integer()) :: :ok
  def clean_exports(format, upload_path, expiration \\ @expiration) do
    "event_participants"
    |> Export.outdated(format, expiration)
    |> Enum.each(&remove_export(&1, upload_path))
  end

  defp remove_export(%Export{file_path: filename} = export, upload_path) do
    full_path = upload_path <> filename
    File.rm(full_path)
    Repo.delete!(export)
  end

  @spec to_list({Participant.t(), Actor.t()}) :: list(String.t())
  def to_list(
        {%Participant{role: role, metadata: metadata, inserted_at: inserted_at},
         %Actor{domain: nil, preferred_username: "anonymous"}}
      ) do
    [
      gettext("Anonymous participant"),
      translate_role(role),
      datetime_to_string(inserted_at, Gettext.get_locale()),
      convert_metadata(metadata)
    ]
  end

  def to_list(
        {%Participant{role: role, metadata: metadata, inserted_at: inserted_at}, %Actor{} = actor}
      ) do
    [
      Actor.display_name_and_username(actor),
      translate_role(role),
      datetime_to_string(inserted_at, Gettext.get_locale()),
      convert_metadata(metadata)
    ]
  end

  @spec convert_metadata(Metadata.t() | nil) :: String.t()
  defp convert_metadata(%Metadata{message: message}) when is_binary(message) do
    message
  end

  defp convert_metadata(_), do: ""

  @spec export_modules :: list(module())
  def export_modules do
    export_config = Application.get_env(:mobilizon, :exports)
    Keyword.get(export_config, :formats, [])
  end

  @spec enabled_formats :: list(String.t())
  def enabled_formats do
    export_modules()
    |> Enum.map(& &1.extension())
  end

  @spec export_enabled?(module()) :: boolean
  def export_enabled?(type) do
    export_config = Application.get_env(:mobilizon, :exports)
    formats = Keyword.get(export_config, :formats, [])
    type in formats
  end

  @default_upload_path "uploads/exports/"

  @spec export_path(String.t()) :: String.t()
  def export_path(extension) do
    [:exports, :path]
    |> Config.get(@default_upload_path)
    |> Path.join(extension)
  end
end
