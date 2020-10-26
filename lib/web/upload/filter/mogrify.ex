# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload/filter/mogrify.ex

defmodule Mobilizon.Web.Upload.Filter.Mogrify do
  @moduledoc """
  Handle mogrify transformations
  """

  @behaviour Mobilizon.Web.Upload.Filter

  alias Mobilizon.Config

  @type conversion :: action :: String.t() | {action :: String.t(), opts :: String.t()}
  @type conversions :: conversion() | [conversion()]

  @spec filter(Mobilizon.Web.Upload.t()) :: {:ok, :atom} | {:error, String.t()}
  def filter(%Mobilizon.Web.Upload{tempfile: file, content_type: "image" <> _}) do
    do_filter(file, Config.get!([__MODULE__, :args]))
    {:ok, :filtered}
  rescue
    _e in ErlangError ->
      {:error, "mogrify command not found"}
  end

  def filter(_), do: {:ok, :noop}

  def do_filter(file, filters) do
    file
    |> Mogrify.open()
    |> mogrify_filter(filters)
    |> Mogrify.save(in_place: true)
  end

  defp mogrify_filter(mogrify, nil), do: mogrify

  defp mogrify_filter(mogrify, [filter | rest]) do
    mogrify
    |> mogrify_filter(filter)
    |> mogrify_filter(rest)
  end

  defp mogrify_filter(mogrify, []), do: mogrify

  defp mogrify_filter(mogrify, {action, options}) do
    Mogrify.custom(mogrify, action, options)
  end

  defp mogrify_filter(mogrify, action) when is_binary(action) do
    Mogrify.custom(mogrify, action)
  end
end
