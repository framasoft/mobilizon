defmodule Mobilizon.Events.Tag.TitleSlug do
  @moduledoc """
  Generates slugs for tags
  """

  alias Mobilizon.Events.Tag
  import Ecto.Query
  alias Mobilizon.Storage.Repo
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
        |> Tag.increment_slug()
        |> build_unique_slug(changeset)
    end
  end
end
