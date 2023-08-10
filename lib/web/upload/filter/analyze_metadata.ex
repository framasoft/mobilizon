# Portions of this file are derived from Pleroma:
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/-/blob/develop/lib/pleroma/upload/filter/analyze_metadata.ex

defmodule Mobilizon.Web.Upload.Filter.AnalyzeMetadata do
  @moduledoc """
  Extracts metadata about the upload, such as width/height
  """
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter

  @behaviour Filter

  @impl Filter
  @spec filter(Upload.t()) ::
          {:ok, :filtered, Upload.t()} | {:ok, :noop}
  def filter(%Upload{tempfile: file, content_type: "image" <> _} = upload) do
    image =
      file
      |> Mogrify.open()
      |> Mogrify.verbose()

    {:ok, :filtered, %Upload{upload | width: image.width, height: image.height}}
  rescue
    e in ErlangError ->
      require Logger
      Logger.warning("#{__MODULE__}: #{inspect(e)}")
      {:ok, :noop}
  end

  def filter(_), do: {:ok, :noop}
end
