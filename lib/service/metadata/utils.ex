defmodule Mobilizon.Service.Metadata.Utils do
  @moduledoc """
  Tools to convert tags to string.
  """

  alias Mobilizon.Service.Formatter.HTML, as: HTMLFormatter
  alias Phoenix.HTML
  import Mobilizon.Web.Gettext

  @slice_limit 200

  @doc """
  Converts list of tags, containing either `t:Phoenix.HTML.safe/0` or strings, to a concatenated string listing the tags
  """
  @spec stringify_tags(list(Phoenix.HTML.safe() | String.t())) :: String.t()
  def stringify_tags(tags), do: Enum.reduce(tags, "", &stringify_tag/2)

  @doc """
  Removes the HTML tags from a text
  """
  @spec strip_tags(String.t()) :: String.t()
  def strip_tags(text), do: HTMLFormatter.strip_tags_and_insert_spaces(text)

  @doc """
  Processes a text and limits it.

  * Removes the HTML tags from a text
  * Slices it to a limit and add an ellipsis character
  * Returns a default description if text is empty
  """
  @spec process_description(String.t(), String.t(), integer()) :: String.t()
  def process_description(description, locale \\ "en", limit \\ @slice_limit)
  def process_description(nil, locale, limit), do: process_description("", locale, limit)

  def process_description("", locale, _limit) do
    default_description(locale)
  end

  def process_description(description, _locale, limit) do
    description
    |> HTMLFormatter.strip_tags_and_insert_spaces()
    |> String.trim()
    |> maybe_slice(limit)
  end

  @doc """
  Returns the default description for a text
  """
  @spec default_description(String.t()) :: String.t()
  def default_description(locale \\ "en") do
    Gettext.put_locale(locale)
    gettext("The event organizer didn't add any description.")
  end

  defp maybe_slice(description, limit) do
    if String.length(description) > limit do
      description
      |> String.slice(0..limit)
      |> String.trim()
      |> (&"#{&1}…").()
    else
      description
    end
  end

  @spec stringify_tag(Phoenix.HTML.safe(), String.t()) :: String.t()
  defp stringify_tag(tag, acc) when is_tuple(tag), do: acc <> HTML.safe_to_string(tag)

  @spec stringify_tag(String.t(), String.t()) :: String.t()
  defp stringify_tag(tag, acc) when is_binary(tag), do: acc <> tag
end
