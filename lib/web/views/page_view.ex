defmodule Mobilizon.Web.PageView do
  @moduledoc """
  View for our webapp
  """

  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Tombstone

  alias Mobilizon.Service.Metadata
  alias Mobilizon.Service.Metadata.Instance
  alias Mobilizon.Service.Metadata.Utils, as: MetadataUtils

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.Convertible

  def render("actor.activity-json", %{conn: %{assigns: %{object: %Actor{} = actor}}}) do
    actor
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Event{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Tombstone{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("comment.activity-json", %{conn: %{assigns: %{object: %Comment{} = comment}}}) do
    comment
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resource.activity-json", %{conn: %{assigns: %{object: %Resource{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render(page, %{object: object, conn: conn} = _assigns)
      when page in ["actor.html", "event.html", "comment.html"] do
    locale = get_locale(conn)
    tags = object |> Metadata.build_tags(locale)
    inject_tags(tags, locale)
  end

  def render("index.html", %{conn: conn}) do
    tags = Instance.build_tags()
    inject_tags(tags, get_locale(conn))
  end

  @spec inject_tags(List.t(), String.t()) :: {:safe, String.t()}
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
  # TODO: Find why it's different in dev/prod and during tests
  defp replace_meta(index_content, tags) do
    index_content
    |> String.replace("<meta name=\"server-injected-data\" />", tags)
    |> String.replace("<meta name=server-injected-data>", tags)
  end

  @spec do_replacements(String.t(), String.t(), String.t()) :: {:safe, String.t()}
  defp do_replacements(index_content, tags, locale) do
    index_content
    |> replace_meta(tags)
    |> String.replace("<html lang=\"en\">", "<html lang=\"#{locale}\">")
    |> String.replace("<html lang=en>", "<html lang=\"#{locale}\">")
    |> (&{:safe, &1}).()
  end

  @spec get_locale(Conn.t()) :: String.t()
  defp get_locale(%{private: %{cldr_locale: nil}}), do: "en"
  defp get_locale(%{private: %{cldr_locale: %{requested_locale_name: locale}}}), do: locale
  defp get_locale(_), do: "en"
end
