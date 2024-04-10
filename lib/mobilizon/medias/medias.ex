defmodule Mobilizon.Medias do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query
  import Mobilizon.Storage.CustomFunctions

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
  Get all media by an URL.
  """
  @spec get_all_media_by_url(String.t()) :: Media.t() | nil
  def get_all_media_by_url(url) do
    url
    |> String.split("?", parts: 2)
    |> hd
    |> media_by_url_query()
    |> Repo.all()
  end

  @doc """
  List the paginated media for user
  """
  @spec medias_for_user(integer | String.t(), integer | nil, integer | nil) :: Page.t(Media.t())
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
  Deletes a media.
  """
  @spec delete_media(Media.t()) :: {:ok, Media.t()} | {:error, Ecto.Changeset.t()}
  def delete_media(%Media{} = media, opts \\ []) do
    transaction =
      Multi.new()
      |> Multi.delete(:media, media)
      |> Multi.run(:remove, fn _repo, %{media: %Media{} = media} ->
        delete_file_from_media(media, opts)
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{media: %Media{} = media}} ->
        {:ok, media}

      {:error, :remove, error, _} ->
        {:error, error}
    end
  end

  @spec delete_file_from_media(Media.t(), Keyword.t()) :: {:ok, Media.t()} | {:error, atom()}
  defp delete_file_from_media(%Media{file: %File{url: url}} = media, opts) do
    if can_delete_media_file?(media) do
      case Upload.remove(url) do
        {:error, err} ->
          if err == :enofile and Keyword.get(opts, :ignore_file_not_found, false) do
            Logger.info("Deleting media and ignoring absent file.")
            {:ok, media}
          else
            {:error, err}
          end

        {:ok, media} ->
          {:ok, media}
      end
    else
      Logger.debug("We cannot delete media file, it's still being used")
      {:ok, media}
    end
  end

  @spec can_delete_media_file?(Media.t()) :: boolean()
  defp can_delete_media_file?(%Media{file: %File{url: url}}) do
    Logger.debug("Checking for other uses of the media file, by comparing it's URL…")

    case get_media_by_url(url) do
      # No other media with this URL
      nil ->
        if url_is_also_a_profile_file?(url) do
          Logger.debug("Found URL in actor profile, so we need to keep the file")
          false
        else
          Logger.debug("All good, we can delete the media file")
          true
        end

      %Media{} ->
        Logger.debug(
          "Found media different from this once for this URL, so there's at least one other media"
        )

        false
    end
  end

  @spec delete_user_profile_media_by_url(String.t()) ::
          {:ok, String.t() | :ignored} | {:error, atom()}
  def delete_user_profile_media_by_url(url) do
    if get_media_by_url(url) == nil && count_occurences_of_url_in_profiles(url) <= 1 do
      # We have no media using this URL and only this profile is using this URL
      Upload.remove(url)
    else
      {:ok, :ignored}
    end
  end

  # Ecto doesn't currently allow us to use exists with a subquery,
  # so we can't create the union through Ecto
  # https://github.com/elixir-ecto/ecto/issues/3619
  @union_query [
                 [from: "events", param: "picture_id"],
                 [from: "events_medias", param: "media_id"],
                 [from: "posts", param: "picture_id"],
                 [from: "posts_medias", param: "media_id"],
                 [from: "comments_medias", param: "media_id"],
                 [from: "admin_settings_medias", param: "media_id"]
               ]
               |> Enum.map_join(" UNION ", fn [from: from, param: param] ->
                 "SELECT 1 FROM #{from} WHERE #{from}.#{param} = m0.id"
               end)
               |> (&"NOT EXISTS(#{&1})").()

  @spec find_media_to_clean(Keyword.t()) :: list(list(Media.t()))
  def find_media_to_clean(opts) do
    default_grace_period =
      Mobilizon.Config.get([:instance, :orphan_upload_grace_period_hours], 48)

    grace_period = Keyword.get(opts, :grace_period, default_grace_period)
    expiration_date = DateTime.add(DateTime.utc_now(), grace_period * -3600)

    query =
      from(m in Media,
        as: :media,
        distinct: true,
        join: a in Actor,
        on: a.id == m.actor_id,
        where: is_nil(a.domain),
        where: m.inserted_at < ^expiration_date,
        where: fragment(@union_query)
      )

    query
    |> Repo.all(timeout: :infinity)
    |> Enum.filter(fn %Media{file: %File{url: url}} ->
      !url_is_also_a_profile_file?(url) && all_media_orphan?(url, expiration_date)
    end)
    |> Enum.chunk_by(fn %Media{file: %File{url: url}} ->
      url
      |> String.split("?", parts: 2)
      |> hd
    end)
  end

  defp all_media_orphan?(url, expiration_date) do
    url
    |> get_all_media_by_url()
    |> Enum.all?(&media_orphan?(&1, expiration_date))
  end

  @spec media_orphan?(Media.t(), DateTime.t()) :: boolean()
  defp media_orphan?(%Media{id: media_id}, expiration_date) do
    media_query =
      from(m in Media,
        as: :media,
        distinct: true,
        join: a in Actor,
        on: a.id == m.actor_id,
        where: m.id == ^media_id,
        where: is_nil(a.domain),
        where: m.inserted_at < ^expiration_date,
        where: fragment(@union_query)
      )

    Repo.exists?(media_query)
  end

  @spec url_is_also_a_profile_file?(String.t()) :: boolean()
  defp url_is_also_a_profile_file?(url) when is_binary(url) do
    count_occurences_of_url_in_profiles(url) > 0
  end

  @spec count_occurences_of_url_in_profiles(String.t()) :: integer()
  defp count_occurences_of_url_in_profiles(url) when is_binary(url) do
    Actor
    |> where([a], fragment("avatar->>'url'") == ^url or fragment("banner->>'url'") == ^url)
    |> Repo.aggregate(:count)
  end

  @spec media_by_url_query(String.t()) :: Ecto.Query.t()
  defp media_by_url_query(url) do
    from(
      p in Media,
      where: split_part(fragment("file->>'url'"), "?", 1) == ^url
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
