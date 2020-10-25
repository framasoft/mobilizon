# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload/filter/dedupe.ex

defmodule Mobilizon.Web.Upload.Filter.Dedupe do
  @moduledoc """
  Names the file after its hash to avoid dedupes
  """
  @behaviour Mobilizon.Web.Upload.Filter
  alias Mobilizon.Web.Upload

  def filter(%Upload{name: name, tempfile: tempfile} = upload) do
    extension = name |> String.split(".") |> List.last()
    shasum = :crypto.hash(:sha256, File.read!(tempfile)) |> Base.encode16(case: :lower)
    filename = shasum <> "." <> extension

    {:ok, :filtered, %Upload{upload | id: shasum, path: filename}}
  end

  def filter(_), do: {:ok, :noop}
end
