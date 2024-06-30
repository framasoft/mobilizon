defmodule Mobilizon.Federation.ActivityStream.Converter.Media do
  @moduledoc """
  Media converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media, as: MediaModel
  alias Mobilizon.Service.HTTP.RemoteMediaDownloaderClient
  alias Mobilizon.Web.Upload

  @doc """
  Convert a media struct to an ActivityStream representation.
  """
  @spec model_to_as(MediaModel.t()) :: ActivityStream.t()
  def model_to_as(%MediaModel{file: file}) do
    %{
      "type" => "Document",
      "mediaType" => file.content_type,
      "url" => file.url,
      "name" => file.name
    }
  end

  @doc """
  Save media data from raw data and return AS Link data.
  """
  @spec find_or_create_media(map(), String.t() | integer()) ::
          {:ok, MediaModel.t()} | {:error, atom() | String.t() | Ecto.Changeset.t()}
  def find_or_create_media(%{"type" => "Link", "href" => url}, actor_id),
    do:
      find_or_create_media(
        %{"type" => "Document", "url" => url, "name" => "External media"},
        actor_id
      )

  def find_or_create_media(
        %{"type" => "Document", "url" => media_url, "name" => name},
        actor_id
      )
      when is_binary(media_url) do
    with {:ok, %{url: url} = uploaded} <- upload_media(media_url, name) do
      case Medias.get_media_by_url(url) do
        %MediaModel{file: _file} = media ->
          {:ok, media}

        nil ->
          Medias.create_media(%{
            file: Map.take(uploaded, [:url, :name, :content_type, :size]),
            metadata: Map.take(uploaded, [:width, :height, :blurhash]),
            actor_id: actor_id
          })
      end
    end
  end

  @spec upload_media(String.t(), String.t()) :: {:ok, map()} | {:error, atom() | String.t()}
  defp upload_media(media_url, ""), do: upload_media(media_url, "unknown")

  defp upload_media(media_url, name) do
    case RemoteMediaDownloaderClient.get(media_url) do
      {:ok, %{body: body}} ->
        case Upload.store(%{body: body, name: name}) do
          {:ok, %{url: _url} = uploaded} ->
            {:ok, uploaded}

          {:error, err} ->
            {:error, err}
        end

      {:error, err} ->
        {:error, err}
    end
  end
end
