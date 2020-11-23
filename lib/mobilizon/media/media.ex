defmodule Mobilizon.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Media.{File, Picture}
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Upload

  @doc """
  Gets a single picture.
  """
  @spec get_picture(integer | String.t()) :: Picture.t() | nil
  def get_picture(id), do: Repo.get(Picture, id)

  @doc """
  Gets a single picture.
  Raises `Ecto.NoResultsError` if the picture does not exist.
  """
  @spec get_picture!(integer | String.t()) :: Picture.t()
  def get_picture!(id), do: Repo.get!(Picture, id)

  @doc """
  Get a picture by its URL.
  """
  @spec get_picture_by_url(String.t()) :: Picture.t() | nil
  def get_picture_by_url(url) do
    url
    |> picture_by_url_query()
    |> Repo.one()
  end

  @doc """
  List the paginated picture for an actor
  """
  @spec pictures_for_actor(integer | String.t(), integer | nil, integer | nil) :: Page.t()
  def pictures_for_actor(actor_id, page, limit) do
    actor_id
    |> pictures_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  List the paginated picture for user
  """
  @spec pictures_for_user(integer | String.t(), integer | nil, integer | nil) :: Page.t()
  def pictures_for_user(user_id, page, limit) do
    user_id
    |> pictures_for_user_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Calculate the sum of media size used by the user
  """
  @spec media_size_for_actor(integer | String.t()) :: integer()
  def media_size_for_actor(actor_id) do
    actor_id
    |> pictures_for_actor_query()
    |> select([:file])
    |> Repo.all()
    |> Enum.map(& &1.file.size)
    |> Enum.sum()
  end

  @doc """
  Calculate the sum of media size used by the user
  """
  @spec media_size_for_user(integer | String.t()) :: integer()
  def media_size_for_user(user_id) do
    user_id
    |> pictures_for_user_query()
    |> select([:file])
    |> Repo.all()
    |> Enum.map(& &1.file.size)
    |> Enum.sum()
  end

  @doc """
  Creates a picture.
  """
  @spec create_picture(map) :: {:ok, Picture.t()} | {:error, Ecto.Changeset.t()}
  def create_picture(attrs \\ %{}) do
    %Picture{}
    |> Picture.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a picture.
  """
  @spec update_picture(Picture.t(), map) :: {:ok, Picture.t()} | {:error, Ecto.Changeset.t()}
  def update_picture(%Picture{} = picture, attrs) do
    picture
    |> Picture.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a picture.
  """
  @spec delete_picture(Picture.t()) :: {:ok, Picture.t()} | {:error, Ecto.Changeset.t()}
  def delete_picture(%Picture{} = picture) do
    transaction =
      Multi.new()
      |> Multi.delete(:picture, picture)
      |> Multi.run(:remove, fn _repo, %{picture: %Picture{file: %File{url: url}}} ->
        Upload.remove(url)
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{picture: %Picture{} = picture}} ->
        {:ok, picture}

      {:error, :remove, error, _} ->
        {:error, error}
    end
  end

  @spec picture_by_url_query(String.t()) :: Ecto.Query.t()
  defp picture_by_url_query(url) do
    from(
      p in Picture,
      where: fragment("? @> ?", p.file, ~s|{"url": "#{url}"}|)
    )
  end

  @spec pictures_for_actor_query(integer() | String.t()) :: Ecto.Query.t()
  defp pictures_for_actor_query(actor_id) do
    Picture
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> where([_p, a], a.id == ^actor_id)
  end

  @spec pictures_for_user_query(integer() | String.t()) :: Ecto.Query.t()
  defp pictures_for_user_query(user_id) do
    Picture
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> join(:inner, [_p, a], u in User, on: a.user_id == u.id)
    |> where([_p, _a, u], u.id == ^user_id)
  end
end
