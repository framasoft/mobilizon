defmodule Mobilizon.Service.Metadata.Utils do
  @moduledoc """
  Tools to convert tags to string.
  """

  alias Mobilizon.Service.Formatter.HTML, as: HTMLFormatter
  alias Phoenix.HTML
  import Mobilizon.Web.Gettext

  @slice_limit 200

  @spec stringify_tags(Enum.t()) :: String.t()
  def stringify_tags(tags), do: Enum.reduce(tags, "", &stringify_tag/2)

  defp stringify_tag(tag, acc) when is_tuple(tag), do: acc <> HTML.safe_to_string(tag)
  defp stringify_tag(tag, acc) when is_binary(tag), do: acc <> tag

  @spec strip_tags(String.t()) :: String.t()
  def strip_tags(text), do: HTMLFormatter.strip_tags(text)

  @spec process_description(String.t(), String.t(), integer()) :: String.t()
  def process_description(description, locale \\ "en", limit \\ @slice_limit)
  def process_description(nil, locale, limit), do: process_description("", locale, limit)

  def process_description("", locale, _limit) do
    Gettext.put_locale(locale)
    gettext("The event organizer didn't add any description.")
  end

  def process_description(description, _locale, limit) do
    description
    |> HTMLFormatter.strip_tags()
    |> String.slice(0..limit)
    |> (&"#{&1}…").()
  end
end
