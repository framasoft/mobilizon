defprotocol Mobilizon.Service.Metadata do
  @moduledoc """
  Service that allows producing metadata HTML tags about content
  """

  @doc """
  Build tags for an entity. Returns a list of `t:Phoenix.HTML.safe/0` tags.

  Locale can be provided to generate fallback descriptions.
  """
  @spec build_tags(any(), String.t()) :: list(Phoenix.HTML.safe())
  def build_tags(entity, locale \\ "en")
end
