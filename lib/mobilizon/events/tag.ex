defmodule Mobilizon.Events.Tag do
  @moduledoc """
  Represents a tag for events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.Tag
  alias Mobilizon.Events.Tag.TitleSlug
  alias Mobilizon.Events.TagRelation

  schema "tags" do
    field(:title, :string)
    field(:slug, TitleSlug.Type)
    many_to_many(:related_tags, Tag, join_through: TagRelation)

    timestamps()
  end

  @doc false
  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:title])
    |> TitleSlug.maybe_generate_slug()
    |> validate_required([:title, :slug])
    |> TitleSlug.unique_constraint()
  end

  def increment_slug(slug) do
    case List.pop_at(String.split(slug, "-"), -1) do
      {nil, _} ->
        slug

      {suffix, slug_parts} ->
        case Integer.parse(suffix) do
          {id, _} -> Enum.join(slug_parts, "-") <> "-" <> Integer.to_string(id + 1)
          :error -> slug <> "-1"
        end
    end
  end
end
