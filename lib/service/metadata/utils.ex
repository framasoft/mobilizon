defmodule Mobilizon.Service.Metadata.Utils do
  @moduledoc """
  Tools to convert tags to string.
  """

  alias Phoenix.HTML

  def stringify_tags(tags), do: Enum.reduce(tags, "", &stringify_tag/2)

  defp stringify_tag(tag, acc) when is_tuple(tag), do: acc <> HTML.safe_to_string(tag)
  defp stringify_tag(tag, acc) when is_binary(tag), do: acc <> tag
end
