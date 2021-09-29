defmodule Mobilizon.Users.Setting.Location do
  @moduledoc """
  Represents user location information
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          range: non_neg_integer(),
          geohash: String.t()
        }

  @required_attrs []

  @optional_attrs [
    :name,
    :range,
    :geohash
  ]

  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:range, :integer)
    field(:geohash, :string)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
  end
end
