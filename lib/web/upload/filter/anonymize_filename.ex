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
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  @impl Filter
  @spec filter(any) :: {:ok, :filtered, Upload.t()} | {:ok, :noop}
  def filter(%Upload{name: name} = upload) do
    extension = List.last(String.split(name, "."))
    name = predefined_name(extension)
    name = if is_nil(name), do: random(extension), else: name
    {:ok, :filtered, %Upload{upload | name: name}}
  end

  @impl Filter
  def filter(_), do: {:ok, :noop}

  @spec predefined_name(String.t()) :: String.t() | nil
  defp predefined_name(extension) do
    case Config.get([__MODULE__, :text]) do
      name when is_valid_string(name) -> String.replace(name, "{extension}", extension)
      _ -> nil
    end
  end

  defp random(extension) do
    string =
      10
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    string <> "." <> extension
  end
end
