defmodule Mobilizon.Posts do
  @moduledoc """
  The Posts context.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Tag
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.{Page, Repo}

  import Ecto.Query
  require Logger

  @post_preloads [:author, :attributed_to, :picture, :media]

  import EctoEnum

  defenum(PostVisibility, :post_visibility, [
    :public,
    :unlisted,
    :restricted,
    :private
  ])

  @spec list_posts_for_stream :: Enum.t()
  def list_posts_for_stream do
    Post
    |> filter_public()
    |> Repo.stream()
  end

  @doc """
  Returns the list of recent posts for a group
  """
  @spec get_posts_for_group(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def get_posts_for_group(%Actor{id: group_id}, page \\ nil, limit \\ nil) do
    group_id
    |> do_get_posts_for_group()
    |> Page.build_page(page, limit)
  end

  @spec get_public_posts_for_group(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def get_public_posts_for_group(%Actor{id: group_id}, page \\ nil, limit \\ nil) do
    group_id
    |> do_get_posts_for_group()
    |> filter_public()
    |> Page.build_page(page, limit)
  end

  @doc """
  Get a post by it's ID
  """
  @spec get_post(integer | String.t()) :: Post.t() | nil
  def get_post(nil), do: nil
  def get_post(id), do: Repo.get(Post, id)

  @spec get_post_with_preloads(integer | String.t()) :: Post.t() | nil
  def get_post_with_preloads(id) do
    Post
    |> Repo.get(id)
    |> Repo.preload(@post_preloads)
  end

  @spec get_post_by_slug(String.t()) :: Post.t() | nil
  def get_post_by_slug(nil), do: nil
  def get_post_by_slug(slug), do: Repo.get_by(Post, slug: slug)

  @spec get_post_by_slug_with_preloads(String.t()) :: Post.t() | nil
  def get_post_by_slug_with_preloads(slug) do
    Post
    |> Repo.get_by(slug: slug)
    |> Repo.preload(@post_preloads)
  end

  @doc """
  Get a post by it's URL
  """
  @spec get_post_by_url(String.t()) :: Post.t() | nil
  def get_post_by_url(url), do: Repo.get_by(Post, url: url)

  @spec get_post_by_url_with_preloads(String.t()) :: Post.t() | nil
  def get_post_by_url_with_preloads(url) do
    Post
    |> Repo.get_by(url: url)
    |> Repo.preload(@post_preloads)
  end

  @doc """
  Creates a post.
  """
  @spec create_post(map) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(attrs \\ %{}) do
    with {:ok, %Post{} = post} <-
           %Post{}
           |> Post.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(post, @post_preloads)}
    end
  end

  @doc """
  Updates a post.
  """
  @spec update_post(Post.t(), map) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def update_post(%Post{} = post, attrs) do
    post
    |> Repo.preload([:tags, :media])
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post
  """
  @spec delete_post(Post.t()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def delete_post(%Post{} = post), do: Repo.delete(post)

  @doc """
  Returns the list of tags for the post.
  """
  @spec list_tags_for_post(integer | String.t()) :: [Tag.t()]
  def list_tags_for_post(post_id) do
    {:ok, uuid} = Ecto.UUID.dump(post_id)

    uuid
    |> tags_for_post_query()
    |> Repo.all()
  end

  @spec tags_for_post_query(integer) :: Ecto.Query.t()
  defp tags_for_post_query(post_id) do
    from(
      t in Tag,
      join: p in "posts_tags",
      on: t.id == p.tag_id,
      where: p.post_id == ^post_id
    )
  end

  @spec filter_public(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_public(query) do
    where(query, [p], p.visibility == ^:public and not p.draft)
  end

  defp do_get_posts_for_group(group_id) do
    Post
    |> where(attributed_to_id: ^group_id)
    |> order_by(desc: :inserted_at)
    |> preload([p], [:author, :attributed_to, :picture, :media, :tags])
  end
end
