defmodule Mobilizon.Medias.Media.Metadata do
  @moduledoc """
  Represents a media metadata
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          width: non_neg_integer(),
          height: non_neg_integer(),
          blurhash: String.t()
        }

  @required_attrs []

  @optional_attrs [
    :width,
    :height,
    :blurhash
  ]

  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  embedded_schema do
    field(:height, :integer)
    field(:width, :integer)
    field(:blurhash, :string)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
  end
end
