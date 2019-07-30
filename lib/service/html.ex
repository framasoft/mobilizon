# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/html.ex

defmodule Mobilizon.Service.HTML do
  @moduledoc """
  Service to filter tags out of HTML content
  """
  alias HtmlSanitizeEx.Scrubber
  alias Mobilizon.Service.HTML.Scrubber.Default

  def filter_tags(html), do: Scrubber.scrub(html, Default)
end

defmodule Mobilizon.Service.HTML.Scrubber.Default do
  @moduledoc "Custom strategy to filter HTML content"

  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta
  # credo:disable-for-previous-line
  # No idea how to fix this one…

  Meta.remove_cdata_sections_before_scrub()
  Meta.strip_comments()

  Meta.allow_tag_with_uri_attributes("a", ["href", "data-user", "data-tag"], ["https", "http"])

  Meta.allow_tag_with_this_attribute_values("a", "class", [
    "hashtag",
    "u-url",
    "mention",
    "u-url mention",
    "mention u-url"
  ])

  Meta.allow_tag_with_this_attribute_values("a", "rel", [
    "tag",
    "nofollow",
    "noopener",
    "noreferrer"
  ])

  Meta.allow_tag_with_these_attributes("a", ["name", "title"])

  Meta.allow_tag_with_these_attributes("abbr", ["title"])

  Meta.allow_tag_with_these_attributes("b", [])
  Meta.allow_tag_with_these_attributes("blockquote", [])
  Meta.allow_tag_with_these_attributes("br", [])
  Meta.allow_tag_with_these_attributes("code", [])
  Meta.allow_tag_with_these_attributes("del", [])
  Meta.allow_tag_with_these_attributes("em", [])
  Meta.allow_tag_with_these_attributes("i", [])
  Meta.allow_tag_with_these_attributes("li", [])
  Meta.allow_tag_with_these_attributes("ol", [])
  Meta.allow_tag_with_these_attributes("p", [])
  Meta.allow_tag_with_these_attributes("pre", [])
  Meta.allow_tag_with_these_attributes("strong", [])
  Meta.allow_tag_with_these_attributes("u", [])
  Meta.allow_tag_with_these_attributes("ul", [])

  Meta.allow_tag_with_this_attribute_values("span", "class", ["h-card"])
  Meta.allow_tag_with_these_attributes("span", [])

  Meta.allow_tag_with_these_attributes("h1", [])
  Meta.allow_tag_with_these_attributes("h2", [])
  Meta.allow_tag_with_these_attributes("h3", [])
  Meta.allow_tag_with_these_attributes("h4", [])
  Meta.allow_tag_with_these_attributes("h5", [])

  Meta.strip_everything_not_covered()
end
