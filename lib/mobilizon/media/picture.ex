defmodule Mobilizon.Media.Picture do
  @moduledoc """
  Represents a picture entity.
  """

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, cast_embed: 2]

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Media.File

  @type t :: %__MODULE__{
          file: File.t(),
          actor: Actor.t()
        }

  schema "pictures" do
    embeds_one(:file, File, on_replace: :update)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:actor_id])
    |> cast_embed(:file)
  end
end
