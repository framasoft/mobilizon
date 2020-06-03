defmodule Mobilizon.Service.Formatter.OEmbed do
  @moduledoc """
  Custom strategy to filter HTML content in OEmbed html
  """

  require FastSanitize.Sanitizer.Meta
  alias FastSanitize.Sanitizer.Meta

  @valid_schemes ~w(https http)

  Meta.strip_comments()

  Meta.allow_tag_with_uri_attributes(:a, ["href"], @valid_schemes)
  Meta.allow_tag_with_uri_attributes(:img, ["src"], @valid_schemes)

  Meta.allow_tag_with_these_attributes(:audio, ["controls"])

  Meta.allow_tag_with_uri_attributes(:embed, ["src"], @valid_schemes)
  Meta.allow_tag_with_these_attributes(:embed, ["height type width"])

  Meta.allow_tag_with_uri_attributes(:iframe, ["src"], @valid_schemes)

  Meta.allow_tag_with_these_attributes(
    :iframe,
    ["allowfullscreen frameborder allow height scrolling width"]
  )

  Meta.allow_tag_with_uri_attributes(:source, ["src"], @valid_schemes)
  Meta.allow_tag_with_these_attributes(:source, ["type"])

  Meta.allow_tag_with_these_attributes(:video, ["controls height loop width"])

  Meta.strip_everything_not_covered()
end
