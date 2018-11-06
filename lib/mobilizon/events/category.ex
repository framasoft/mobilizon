defmodule Mobilizon.Events.Category do
  @moduledoc """
  Represents a category for events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.Category
  use Arc.Ecto.Schema

  schema "categories" do
    field(:description, :string)
    field(:picture, MobilizonWeb.Uploaders.Category.Type)
    field(:title, :string, null: false)

    timestamps()
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, [:title, :description])
    |> cast_attachments(attrs, [:picture])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end
