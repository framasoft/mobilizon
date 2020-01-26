# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload/filter/anonymize_filename.ex

defmodule Mobilizon.Web.Upload.Filter.AnonymizeFilename do
  @moduledoc """
  Replaces the original filename with a pre-defined text or randomly generated string.

  Should be used after `Mobilizon.Web.Upload.Filter.Dedupe`.
  """

  @behaviour Mobilizon.Web.Upload.Filter

  alias Mobilizon.Config

  def filter(upload) do
    extension = List.last(String.split(upload.name, "."))
    name = Config.get([__MODULE__, :text], random(extension))
    {:ok, %Mobilizon.Web.Upload{upload | name: name}}
  end

  defp random(extension) do
    string =
      10
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    string <> "." <> extension
  end
end
