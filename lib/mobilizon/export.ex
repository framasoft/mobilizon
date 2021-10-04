defmodule Mobilizon.Export do
  @moduledoc """
  Manage exported files
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [where: 3]
  alias Mobilizon.Storage.Repo

  @type t :: %__MODULE__{
          file_path: String.t(),
          file_name: String.t() | nil,
          file_size: integer() | nil,
          type: String.t(),
          reference: String.t(),
          format: String.t()
        }

  @required_attrs [:file_path, :type, :reference, :format]
  @optional_attrs [:file_size, :file_name]
  @attrs @required_attrs ++ @optional_attrs

  schema "exports" do
    field(:file_path, :string)
    field(:file_size, :integer)
    field(:file_name, :string)
    field(:type, :string)
    field(:reference, :string)
    field(:format, :string)

    timestamps()
  end

  @doc false
  def changeset(export, attrs) do
    export
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end

  @spec get_export(String.t(), String.t(), String.t()) :: t() | nil
  def get_export(file_path, type, format) do
    __MODULE__
    |> where([e], e.file_path == ^file_path and e.type == ^type and e.format == ^format)
    |> Repo.one()
  end

  @spec outdated(String.t(), String.t(), integer()) :: list(t())
  def outdated(type, format, expiration) do
    expiration_date = DateTime.add(DateTime.utc_now(), -expiration)

    __MODULE__
    |> where([e], e.type == ^type and e.format == ^format and e.updated_at < ^expiration_date)
    |> Repo.all()
  end
end
