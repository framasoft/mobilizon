defmodule Eventos.Events.Tag.TitleSlug do
  @moduledoc """
  Generates slugs for tags
  """
  alias Eventos.Events.Tag
  import Ecto.Query
  alias Eventos.Repo
  use EctoAutoslugField.Slug, from: :title, to: :slug

  def build_slug(sources, changeset) do
    slug = super(sources, changeset)
    build_unique_slug(slug, changeset)
  end

  defp build_unique_slug(slug, changeset) do
    query = from t in Tag,
                 where: t.slug == ^slug

    case Repo.one(query) do
      nil -> slug
      _story ->
        slug
        |> Eventos.Slug.increment_slug()
        |> build_unique_slug(changeset)
    end
  end
end

defmodule Eventos.Events.Tag do
  @moduledoc """
  Represents a tag for events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.Tag
  alias Eventos.Events.Tag.TitleSlug

  schema "tags" do
    field :title, :string
    field :slug, TitleSlug.Type

    timestamps()
  end

  @doc false
  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end
end
