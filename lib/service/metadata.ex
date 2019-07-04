defprotocol Mobilizon.Service.Metadata do
  @doc """
  Build tags
  """
  def build_tags(entity)
end

defmodule Mobilizon.Service.MetadataUtils do
  @moduledoc """
  Tools to convert tags to string
  """
  alias Phoenix.HTML

  def stringify_tags(tags) do
    Enum.reduce(tags, "", &stringify_tag/2)
  end

  defp stringify_tag(tag, acc) when is_tuple(tag), do: acc <> HTML.safe_to_string(tag)
  defp stringify_tag(tag, acc) when is_binary(tag), do: acc <> tag
end
