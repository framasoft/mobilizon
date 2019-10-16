defmodule Mobilizon.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Mobilizon.Media.{File, Picture}
  alias Mobilizon.Storage.Repo

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
        MobilizonWeb.Upload.remove(url)
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
end
