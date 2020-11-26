defmodule Mobilizon.Medias do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Medias.{File, Media}
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Upload
  require Logger

  @doc """
  Gets a single media.
  """
  @spec get_media(integer | String.t()) :: Media.t() | nil
  def get_media(id), do: Repo.get(Media, id)

  @doc """
  Gets a single media.
  Raises `Ecto.NoResultsError` if the media does not exist.
  """
  @spec get_media!(integer | String.t()) :: Media.t()
  def get_media!(id), do: Repo.get!(Media, id)

  @doc """
  Get a media by its URL.
  """
  @spec get_media_by_url(String.t()) :: Media.t() | nil
  def get_media_by_url(url) do
    url
    |> media_by_url_query()
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Get an unattached media by it's URL
  """
  def get_unattached_media_by_url(url) do
    url
    |> media_by_url_query()
    |> join(:left, [m], e in assoc(m, :events))
    |> join(:left, [m], ep in assoc(m, :event_picture))
    |> join(:left, [m], p in assoc(m, :posts))
    |> join(:left, [m], pp in assoc(m, :posts_picture))
    |> join(:left, [m], c in assoc(m, :comments))
    |> where([_m, e], is_nil(e.id))
    |> where([_m, _e, ep], is_nil(ep.id))
    |> where([_m, _e, _ep, p], is_nil(p.id))
    |> where([_m, _e, _ep, _p, pp], is_nil(pp.id))
    |> where([_m, _e, _ep, _p, _pp, c], is_nil(c.id))
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  List the paginated media for an actor
  """
  @spec medias_for_actor(integer | String.t(), integer | nil, integer | nil) :: Page.t()
  def medias_for_actor(actor_id, page, limit) do
    actor_id
    |> medias_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  List the paginated media for user
  """
  @spec medias_for_user(integer | String.t(), integer | nil, integer | nil) :: Page.t()
  def medias_for_user(user_id, page, limit) do
    user_id
    |> medias_for_user_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Calculate the sum of media size used by the user
  """
  @spec media_size_for_actor(integer | String.t()) :: integer()
  def media_size_for_actor(actor_id) do
    actor_id
    |> medias_for_actor_query()
    |> select([:file])
    |> Repo.all()
    |> Enum.map(& &1.file.size)
    |> Enum.filter(& &1)
    |> Enum.sum()
  end

  @doc """
  Calculate the sum of media size used by the user
  """
  @spec media_size_for_user(integer | String.t()) :: integer()
  def media_size_for_user(user_id) do
    user_id
    |> medias_for_user_query()
    |> select([:file])
    |> Repo.all()
    |> Enum.map(& &1.file.size)
    |> Enum.sum()
  end

  @doc """
  Creates a media.
  """
  @spec create_media(map) :: {:ok, Media.t()} | {:error, Ecto.Changeset.t()}
  def create_media(attrs \\ %{}) do
    %Media{}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a media.
  """
  @spec update_media(Media.t(), map) :: {:ok, Media.t()} | {:error, Ecto.Changeset.t()}
  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a media.
  """
  @spec delete_media(Media.t()) :: {:ok, Media.t()} | {:error, Ecto.Changeset.t()}
  def delete_media(%Media{} = media, opts \\ []) do
    transaction =
      Multi.new()
      |> Multi.delete(:media, media)
      |> Multi.run(:remove, fn _repo, %{media: %Media{file: %File{url: url}} = media} ->
        case Upload.remove(url) do
          {:error, err} ->
            if err =~ "doesn't exist" and Keyword.get(opts, :ignore_file_not_found, false) do
              Logger.info("Deleting media and ignoring absent file.")
              {:ok, media}
            else
              {:error, err}
            end

          {:ok, media} ->
            {:ok, media}
        end
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{media: %Media{} = media}} ->
        {:ok, media}

      {:error, :remove, error, _} ->
        {:error, error}
    end
  end

  @spec media_by_url_query(String.t()) :: Ecto.Query.t()
  defp media_by_url_query(url) do
    from(
      p in Media,
      where: fragment("? @> ?", p.file, ~s|{"url": "#{url}"}|)
    )
  end

  @spec medias_for_actor_query(integer() | String.t()) :: Ecto.Query.t()
  defp medias_for_actor_query(actor_id) do
    Media
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> where([_p, a], a.id == ^actor_id)
  end

  @spec medias_for_user_query(integer() | String.t()) :: Ecto.Query.t()
  defp medias_for_user_query(user_id) do
    Media
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> join(:inner, [_p, a], u in User, on: a.user_id == u.id)
    |> where([_p, _a, u], u.id == ^user_id)
  end
end
