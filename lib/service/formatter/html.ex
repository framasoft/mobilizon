# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/html.ex

defmodule Mobilizon.Service.Formatter.HTML do
  @moduledoc """
  Service to filter tags out of HTML content.
  """

  alias FastSanitize.Sanitizer

  alias Mobilizon.Service.Formatter.{DefaultScrubbler, OEmbed}

  def filter_tags(html), do: Sanitizer.scrub(html, DefaultScrubbler)

  def strip_tags(html) do
    case FastSanitize.strip_tags(html) do
      {:ok, html} ->
        HtmlEntities.decode(html)

      _ ->
        raise "Failed to filter tags"
    end
  end

  @doc """
  Inserts a space before tags closing so that words are not attached once tags stripped

  `<h1>test</h1>next` thing becomes `test next` instead of `testnext`
  """
  @spec strip_tags_and_insert_spaces(String.t()) :: String.t()
  def strip_tags_and_insert_spaces(html) when is_binary(html) do
    html
    |> String.replace("><", "> <")
    |> strip_tags()
  end

  def strip_tags_and_insert_spaces(html), do: html

  def filter_tags_for_oembed(html), do: Sanitizer.scrub(html, OEmbed)
end
