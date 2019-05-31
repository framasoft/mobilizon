defmodule Mobilizon.Media.Picture do
  @moduledoc """
  Represents a picture entity
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Media.File
  alias Mobilizon.Actors.Actor

  schema "pictures" do
    embeds_one(:file, File, on_replace: :update)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:actor_id])
    |> cast_embed(:file)
  end
end
