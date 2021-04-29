defmodule Mobilizon.Events.Tag do
  @moduledoc """
  Represents a tag for events.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.Tag.TitleSlug
  alias Mobilizon.Events.TagRelation

  @type t :: %__MODULE__{
          title: String.t(),
          slug: TitleSlug.Type.t(),
          related_tags: [t]
        }

  @required_attrs [:title, :slug]
  @attrs @required_attrs

  schema "tags" do
    field(:title, :string)
    field(:slug, TitleSlug.Type)

    many_to_many(:related_tags, __MODULE__, join_through: TagRelation)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = tag, attrs) do
    tag
    |> cast(attrs, @attrs)
    |> TitleSlug.maybe_generate_slug()
    |> validate_required(@required_attrs)
    |> TitleSlug.unique_constraint()
    |> validate_length(:title, min: 2, max: 40)
    |> validate_length(:slug, min: 2, max: 40)
  end
end
