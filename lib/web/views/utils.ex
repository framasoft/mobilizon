defmodule Mobilizon.Web.Views.Utils do
  @moduledoc """
  Utils for views
  """

  alias Mobilizon.Service.Metadata.Utils, as: MetadataUtils
  import Mobilizon.Web.Gettext, only: [dgettext: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1]

  # sobelow_skip ["Traversal.FileModule"]
  @spec inject_tags(Enum.t(), String.t()) :: {:ok, {:safe, String.t()}}
  def inject_tags(tags, locale \\ "en") do
    with path <- Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html"),
         {:exists, true} <- {:exists, File.exists?(path)},
         {:ok, index_content} <- File.read(path),
         safe <- do_replacements(index_content, MetadataUtils.stringify_tags(tags), locale) do
      {:ok, {:safe, safe}}
    else
      {:exists, false} -> {:error, :index_not_found}
    end
  end

  @spec return_error(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def return_error(conn, error) do
    conn
    |> put_status(500)
    |> Phoenix.Controller.put_view(Mobilizon.Web.ErrorView)
    |> Phoenix.Controller.render("500.html", %{details: details(error)})
    |> halt()
  end

  defp details(:index_not_found) do
    [dgettext("errors", "Index file not found. You need to recompile the front-end.")]
  end

  defp details(_) do
    []
  end

  @spec replace_meta(String.t(), String.t()) :: String.t()
  defp replace_meta(index_content, tags) do
    index_content
    |> String.replace("<meta name=\"server-injected-data\">", tags)
    |> String.replace("<meta name=\"server-injected-data\" />", tags)
  end

  @spec do_replacements(String.t(), String.t(), String.t()) :: String.t()
  defp do_replacements(index_content, tags, locale) do
    index_content
    |> replace_meta(tags)
    |> String.replace("<html lang=\"en\">", "<html lang=\"#{locale}\">")
  end

  @spec get_locale(Conn.t()) :: String.t()
  def get_locale(%{private: %{cldr_locale: nil}}), do: "en"
  def get_locale(%{private: %{cldr_locale: %{requested_locale_name: locale}}}), do: locale
  def get_locale(_), do: "en"
end
