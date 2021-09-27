defmodule Mobilizon.Actors.Member.Metadata do
  @moduledoc """
  Represents metadata on a membership
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @required_attrs []

  @optional_attrs []

  @attrs @required_attrs ++ @optional_attrs

  embedded_schema do
    # TODO : Use this space to put notes when someone is invited / requested to join
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
  end
end
