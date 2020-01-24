# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/html.ex

defmodule Mobilizon.Service.Formatter.HTML do
  @moduledoc """
  Service to filter tags out of HTML content.
  """

  alias HtmlSanitizeEx.Scrubber

  alias Mobilizon.Service.Formatter.DefaultScrubbler

  def filter_tags(html), do: Scrubber.scrub(html, DefaultScrubbler)
end
