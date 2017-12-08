defmodule Eventos.Events.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.Category


  schema "categories" do
    field :picture, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, [:title, :picture])
    |> validate_required([:title, :picture])
    |> unique_constraint(:title)
  end
end
