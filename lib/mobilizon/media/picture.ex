defmodule Mobilizon.Media.Picture do
  @moduledoc """
  Represents a picture entity
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Media.File

  schema "pictures" do
    embeds_one(:file, File, on_replace: :update)

    timestamps()
  end

  @doc false
  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [])
    |> cast_embed(:file)
  end
end
