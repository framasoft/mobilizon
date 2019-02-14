defmodule Mobilizon.Events.Tag.TitleSlug do
  @moduledoc """
  Generates slugs for tags
  """
  alias Mobilizon.Events.Tag
  import Ecto.Query
  alias Mobilizon.Repo
  use EctoAutoslugField.Slug, from: :title, to: :slug

  def build_slug(sources, changeset) do
    slug = super(sources, changeset)
    build_unique_slug(slug, changeset)
  end

  defp build_unique_slug(slug, changeset) do
    query =
      from(
        t in Tag,
        where: t.slug == ^slug
      )

    case Repo.one(query) do
      nil ->
        slug

      _tag ->
        slug
        |> Mobilizon.Ecto.increment_slug()
        |> build_unique_slug(changeset)
    end
  end
end

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
end
