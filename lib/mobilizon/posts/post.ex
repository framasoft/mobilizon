defmodule Mobilizon.Posts.Post.TitleSlug do
  @moduledoc """
  Module to generate the slug for posts
  """
  use EctoAutoslugField.Slug, from: [:title, :id], to: :slug

  def build_slug([title, id], %Ecto.Changeset{valid?: true}) do
    [title, ShortUUID.encode!(id)]
    |> Enum.join("-")
    |> Slugger.slugify()
  end

  def build_slug(_sources, %Ecto.Changeset{valid?: false}), do: ""
end

defmodule Mobilizon.Posts.Post do
  @moduledoc """
  Module that represent Posts published by groups
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Tag
  alias Mobilizon.Media.Picture
  alias Mobilizon.Posts.Post.TitleSlug
  alias Mobilizon.Posts.PostVisibility
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @type t :: %__MODULE__{
          url: String.t(),
          local: boolean,
          slug: String.t(),
          body: String.t(),
          title: String.t(),
          draft: boolean,
          visibility: PostVisibility.t(),
          publish_at: DateTime.t(),
          author: Actor.t(),
          attributed_to: Actor.t(),
          picture: Picture.t(),
          tags: [Tag.t()]
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "posts" do
    field(:body, :string)
    field(:draft, :boolean, default: false)
    field(:local, :boolean, default: true)
    field(:slug, TitleSlug.Type)
    field(:title, :string)
    field(:url, :string)
    field(:publish_at, :utc_datetime)
    field(:visibility, PostVisibility, default_value: :public)
    belongs_to(:author, Actor)
    belongs_to(:attributed_to, Actor)
    belongs_to(:picture, Picture, on_replace: :update)
    many_to_many(:tags, Tag, join_through: "posts_tags", on_replace: :delete)

    timestamps()
  end

  @required_attrs [
    :id,
    :title,
    :body,
    :draft,
    :slug,
    :url,
    :author_id,
    :attributed_to_id
  ]
  @optional_attrs [:picture_id, :local, :publish_at, :visibility]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(%__MODULE__{} = post, attrs) do
    post
    |> cast(attrs, @attrs)
    |> maybe_generate_id()
    |> put_tags(attrs)
    |> maybe_put_publish_date()
    # Validate ID and title here because they're needed for slug
    |> validate_required([:id, :title])
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
    |> maybe_generate_url()
    |> validate_required(@required_attrs)
  end

  defp maybe_generate_id(%Ecto.Changeset{} = changeset) do
    case fetch_field(changeset, :id) do
      res when res in [:error, {:data, nil}] ->
        put_change(changeset, :id, Ecto.UUID.generate())

      _ ->
        changeset
    end
  end

  @spec maybe_generate_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_generate_url(%Ecto.Changeset{} = changeset) do
    with res when res in [:error, {:data, nil}] <- fetch_field(changeset, :url),
         {changes, id_and_slug} when changes in [:changes, :data] <-
           fetch_field(changeset, :slug),
         url <- generate_url(id_and_slug) do
      put_change(changeset, :url, url)
    else
      _ -> changeset
    end
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(id_and_slug), do: Routes.page_url(Endpoint, :post, id_and_slug)

  @spec put_tags(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_tags(changeset, %{"tags" => tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, %{tags: tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, _), do: changeset

  defp process_tag(tag), do: Tag.changeset(%Tag{}, tag)

  defp maybe_put_publish_date(%Changeset{} = changeset) do
    publish_at =
      if get_field(changeset, :draft, true) == false,
        do: DateTime.utc_now() |> DateTime.truncate(:second),
        else: nil

    put_change(changeset, :publish_at, publish_at)
  end
end
