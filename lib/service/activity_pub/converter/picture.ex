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
      "url" => [
        %{
          "type" => "Link",
          "mediaType" => file.content_type,
          "href" => file.url
        }
      ],
      "name" => file.name
    }
  end
end
