defmodule Mobilizon.Federation.ActivityStream.Converter.Media do
  @moduledoc """
  Media converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media, as: MediaModel

  alias Mobilizon.Web.Upload

  @http_options [
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  @doc """
  Convert a media struct to an ActivityStream representation.
  """
  @spec model_to_as(MediaModel.t()) :: map
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
  def find_or_create_media(%{"type" => "Link", "href" => url}, actor_id),
    do: find_or_create_media(url, actor_id)

  def find_or_create_media(
        %{"type" => "Document", "url" => media_url, "name" => name},
        actor_id
      )
      when is_binary(media_url) do
    with {:ok, %{body: body}} <- Tesla.get(media_url, opts: @http_options),
         {:ok, %{name: name, url: url, content_type: content_type, size: size}} <-
           Upload.store(%{body: body, name: name}),
         {:media_exists, nil} <- {:media_exists, Medias.get_media_by_url(url)} do
      Medias.create_media(%{
        "file" => %{
          "url" => url,
          "name" => name,
          "content_type" => content_type,
          "size" => size
        },
        "actor_id" => actor_id
      })
    else
      {:media_exists, %MediaModel{file: _file} = media} ->
        {:ok, media}

      err ->
        err
    end
  end
end
