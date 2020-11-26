defmodule Mobilizon.Medias.File do
  @moduledoc """
  Represents a file entity.
  """

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t(),
          content_type: String.t(),
          size: integer
        }

  @required_attrs [:name, :url]
  @optional_attrs [:content_type, :size]
  @attrs @required_attrs ++ @optional_attrs

  @derive Jason.Encoder
  embedded_schema do
    field(:name, :string)
    field(:url, :string)
    field(:content_type, :string)
    field(:size, :integer)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = file, attrs) do
    file
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
