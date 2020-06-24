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
        html

      _ ->
        raise "Failed to filter tags"
    end
  end

  def filter_tags_for_oembed(html), do: Sanitizer.scrub(html, OEmbed)
end
