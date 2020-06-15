defprotocol Mobilizon.Service.Metadata do
  @doc """
  Build tags
  """

  def build_tags(entity, locale \\ "en")
end
