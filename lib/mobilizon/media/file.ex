defmodule Mobilizon.Media.File do
  @moduledoc """
  Represents a file entity
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:url, :string)
    field(:content_type, :string)

    timestamps()
  end

  @doc false
  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:name, :url, :content_type])
    |> validate_required([:name, :url])
  end
end
