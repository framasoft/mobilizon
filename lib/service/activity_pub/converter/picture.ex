defmodule Mobilizon.Service.ActivityPub.Converter.Picture do
  @moduledoc """
  Picture converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Media.Picture, as: PictureModel

  @doc """
  Convert a picture struct to an ActivityStream representation.
  """
  @spec model_to_as(PictureModel.t()) :: map
  def model_to_as(%PictureModel{file: file}) do
    %{
      "type" => "Document",
      "mediaType" => file.content_type,
      "url" => file.url,
      "name" => file.name
    }
  end

  @doc """
  Save picture data from raw data and return AS Link data.
  """
  def find_or_create_picture(%{"type" => "Link", "href" => url}, actor_id),
    do: find_or_create_picture(url, actor_id)

  def find_or_create_picture(
        %{"type" => "Document", "url" => picture_url, "name" => name},
        actor_id
      )
      when is_bitstring(picture_url) do
    with {:ok, %HTTPoison.Response{body: body}} <- HTTPoison.get(picture_url),
         {:ok,
          %{
            name: name,
            url: url,
            content_type: content_type,
            size: size
          }} <-
           MobilizonWeb.Upload.store(%{body: body, name: name}),
         {:picture_exists, nil} <- {:picture_exists, Mobilizon.Media.get_picture_by_url(url)} do
      Mobilizon.Media.create_picture(%{
        "file" => %{
          "url" => url,
          "name" => name,
          "content_type" => content_type,
          "size" => size
        },
        "actor_id" => actor_id
      })
    else
      {:picture_exists, %PictureModel{file: _file} = picture} ->
        {:ok, picture}

      err ->
        err
    end
  end
end
