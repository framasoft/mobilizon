defmodule Mobilizon.Posts.Post.TitleSlug do
  @moduledoc """
  Module to generate the slug for posts
  """
  use EctoAutoslugField.Slug, from: [:title, :id], to: :slug

  @spec build_slug([String.t()], any()) :: String.t() | nil
  def build_slug([title, id], _changeset) do
    [title, ShortUUID.encode!(id)]
    |> Enum.join("-")
    |> Slugger.slugify()
  end

  def build_slug(_, _), do: nil
end

defmodule Mobilizon.Posts.Post do
  @moduledoc """
  Module that represent Posts published by groups
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Events, Medias}
  alias Mobilizon.Events.Tag
  alias Mobilizon.Medias.Media
  alias Mobilizon.Posts.Post.TitleSlug
  alias Mobilizon.Posts.PostVisibility
  use Mobilizon.Web, :verified_routes
  import Mobilizon.Web.Gettext

  @type t :: %__MODULE__{
          id: String.t(),
          url: String.t(),
          local: boolean,
          slug: String.t(),
          body: String.t(),
          title: String.t(),
          draft: boolean,
          visibility: atom(),
          publish_at: DateTime.t(),
          author: Actor.t(),
          attributed_to: Actor.t(),
          picture: Media.t(),
          media: [Media.t()],
          tags: [Tag.t()],
          language: String.t()
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
    field(:visibility, PostVisibility, default: :public)
    field(:language, :string, default: "und")
    belongs_to(:author, Actor)
    belongs_to(:attributed_to, Actor)
    belongs_to(:picture, Media, on_replace: :update)
    many_to_many(:tags, Tag, join_through: "posts_tags", on_replace: :delete)
    many_to_many(:media, Media, join_through: "posts_medias", on_replace: :delete)

    timestamps(type: :utc_datetime)
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
  @optional_attrs [:picture_id, :local, :publish_at, :visibility, :language]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = post, attrs) do
    post
    |> cast(attrs, @attrs)
    |> maybe_generate_id()
    |> put_assoc(:media, Map.get(attrs, :media, []))
    |> put_tags(attrs)
    |> maybe_put_publish_date()
    |> put_picture(attrs)
    # Validate ID and title here because they're needed for slug
    |> validate_required(:id)
    |> validate_required(:title, message: gettext("A title is required for the post"))
    |> validate_required(:body, message: gettext("A text is required for the post"))
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
    |> maybe_generate_url()
    |> validate_required(@required_attrs -- [:slug, :url])
    |> unique_constraint(:url)
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
         url when is_binary(url) <- generate_url(id_and_slug) do
      put_change(changeset, :url, url)
    else
      _ -> changeset
    end
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(id_and_slug) when is_binary(id_and_slug),
    do: url(~p"/p/#{id_and_slug}")

  defp generate_url(_), do: nil

  @spec put_tags(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_tags(changeset, %{"tags" => tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, %{tags: tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, _), do: changeset

  @spec process_tag(map() | Tag.t()) :: Tag.t() | Ecto.Changeset.t()
  # We need a changeset instead of a raw struct because of slug which is generated in changeset
  defp process_tag(%{id: id} = _tag) do
    Events.get_tag(id)
  end

  defp process_tag(tag), do: Tag.changeset(%Tag{}, tag)

  defp maybe_put_publish_date(%Changeset{} = changeset) do
    default_publish_at =
      if get_field(changeset, :draft, true) == false,
        do: DateTime.utc_now() |> DateTime.truncate(:second),
        else: nil

    publish_at = get_change(changeset, :publish_at, default_publish_at)
    put_change(changeset, :publish_at, publish_at)
  end

  # In case the provided picture is an existing one
  @spec put_picture(Changeset.t(), map) :: Changeset.t()
  defp put_picture(%Changeset{} = changeset, %{picture: %{picture_id: id} = _picture}) do
    %Media{} = picture = Medias.get_media!(id)
    put_assoc(changeset, :picture, picture)
  end

  # In case it's a new picture
  defp put_picture(%Changeset{} = changeset, _attrs) do
    cast_assoc(changeset, :picture)
  end

  @doc """
  Whether we can show the post. Returns false if the organizer actor or group is suspended
  """
  @spec show?(t) :: boolean()
  def show?(%__MODULE__{attributed_to: %Actor{suspended: true}}), do: false
  def show?(%__MODULE__{author: %Actor{suspended: true}}), do: false
  def show?(%__MODULE__{}), do: true
end
