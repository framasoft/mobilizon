defmodule Mobilizon.Web.Views.Utils do
  @moduledoc """
  Utils for views
  """

  alias Mobilizon.Service.Metadata.Utils, as: MetadataUtils
  import Mobilizon.Web.Gettext, only: [dgettext: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1]

  # sobelow_skip ["Traversal.FileModule"]
  @spec inject_tags(Enum.t(), String.t()) :: {:ok, {:safe, String.t()}} | {:error, atom()}
  def inject_tags(tags, locale \\ "en") do
    with path <- Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html"),
         {:exists, true} <- {:exists, File.exists?(path)},
         {:ok, index_content} <- File.read(path),
         safe <- do_replacements(index_content, MetadataUtils.stringify_tags(tags), locale) do
      {:ok, {:safe, safe}}
    else
      {:exists, false} -> {:error, :index_not_found}
      {:error, error} when is_atom(error) -> {:error, error}
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
    |> String.replace("<meta name=\"server-injected-data\"/>", tags)
    |> String.replace("<meta name=\"server-injected-data\" />", tags)
  end

  @spec do_replacements(String.t(), String.t(), String.t()) :: String.t()
  defp do_replacements(index_content, tags, locale) do
    index_content
    |> replace_meta(tags)
    |> String.replace(
      ~s(<html lang="en" dir="auto">),
      ~s(<html lang="#{locale}" dir="#{get_language_direction(locale)}">)
    )
  end

  @spec get_locale(Plug.Conn.t()) :: String.t()
  def get_locale(%Plug.Conn{assigns: assigns}) do
    Map.get(assigns, :locale)
  end

  @ltr_languages ["ar", "ae", "he", "fa", "ku", "ur"]

  @spec get_language_direction(String.t()) :: String.t()
  defp get_language_direction(locale) when locale in @ltr_languages, do: "rtl"
  defp get_language_direction(_locale), do: "ltr"
end
