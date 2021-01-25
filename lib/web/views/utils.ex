defmodule Mobilizon.Web.Views.Utils do
  @moduledoc """
  Utils for views
  """

  alias Mobilizon.Service.Metadata.Utils, as: MetadataUtils

  # sobelow_skip ["Traversal.FileModule"]
  @spec inject_tags(Enum.t(), String.t()) :: {:safe, String.t()}
  def inject_tags(tags, locale \\ "en") do
    with {:ok, index_content} <- File.read(index_file_path()) do
      do_replacements(index_content, MetadataUtils.stringify_tags(tags), locale)
    end
  end

  @spec index_file_path :: String.t()
  defp index_file_path do
    Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html")
  end

  @spec replace_meta(String.t(), String.t()) :: String.t()
  defp replace_meta(index_content, tags) do
    index_content
    |> String.replace("<meta name=\"server-injected-data\">", tags)
    |> String.replace("<meta name=\"server-injected-data\" />", tags)
  end

  @spec do_replacements(String.t(), String.t(), String.t()) :: {:safe, String.t()}
  defp do_replacements(index_content, tags, locale) do
    index_content
    |> replace_meta(tags)
    |> String.replace("<html lang=\"en\">", "<html lang=\"#{locale}\">")
    |> (&{:safe, &1}).()
  end

  @spec get_locale(Conn.t()) :: String.t()
  def get_locale(%{private: %{cldr_locale: nil}}), do: "en"
  def get_locale(%{private: %{cldr_locale: %{requested_locale_name: locale}}}), do: locale
  def get_locale(_), do: "en"
end
