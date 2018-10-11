defmodule Mobilizon.Events.Category do
  @moduledoc """
  Represents a category for events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.Category

  schema "categories" do
    field(:description, :string)
    field(:picture, :string)
    field(:title, :string, null: false)

    timestamps()
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, [:title, :description, :picture])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end
