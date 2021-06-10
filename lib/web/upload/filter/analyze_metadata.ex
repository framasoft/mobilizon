# Portions of this file are derived from Pleroma:
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/-/blob/develop/lib/pleroma/upload/filter/analyze_metadata.ex

defmodule Mobilizon.Web.Upload.Filter.AnalyzeMetadata do
  @moduledoc """
  Extracts metadata about the upload, such as width/height
  """
  require Logger
  alias Mobilizon.Web.Upload

  @behaviour Mobilizon.Web.Upload.Filter

  @spec filter(Upload.t()) ::
          {:ok, :filtered, Upload.t()} | {:ok, :noop} | {:error, String.t()}
  def filter(%Upload{tempfile: file, content_type: "image" <> _} = upload) do
    image =
      file
      |> Mogrify.open()
      |> Mogrify.verbose()

    upload =
      upload
      |> Map.put(:width, image.width)
      |> Map.put(:height, image.height)
      |> Map.put(:blurhash, get_blurhash(file))

    {:ok, :filtered, upload}
  rescue
    e in ErlangError ->
      Logger.warn("#{__MODULE__}: #{inspect(e)}")
      {:ok, :noop}
  end

  def filter(_), do: {:ok, :noop}

  defp get_blurhash(file) do
    case :eblurhash.magick(to_charlist(file)) do
      {:ok, blurhash} ->
        to_string(blurhash)

      _ ->
        nil
    end
  end
end
