defmodule Mobilizon.Events.EventMetadata do
  @moduledoc """
  Participation stats on event
  """

  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  defenum(EventMetadataTypeEnum, string: 0, integer: 1, boolean: 2, float: 3)

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }

  @required_attrs [
    :key,
    :value
  ]

  @optional_attrs [
    :title,
    :type
  ]

  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:key, :string)
    field(:title, :string)
    field(:value, :string)
    field(:type, EventMetadataTypeEnum, default: :string)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event_metadata, attrs) do
    event_metadata
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
