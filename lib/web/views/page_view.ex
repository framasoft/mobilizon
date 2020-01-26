defmodule Mobilizon.Web.PageView do
  @moduledoc """
  View for our webapp
  """

  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Comment, Event}
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

  def render(page, %{object: object} = _assigns)
      when page in ["actor.html", "event.html", "comment.html"] do
    with {:ok, index_content} <- File.read(index_file_path()) do
      tags = object |> Metadata.build_tags() |> MetadataUtils.stringify_tags()

      index_content = replace_meta(index_content, tags)

      {:safe, index_content}
    end
  end

  def render("index.html", _assigns) do
    with {:ok, index_content} <- File.read(index_file_path()) do
      tags = Instance.build_tags() |> MetadataUtils.stringify_tags()

      index_content = replace_meta(index_content, tags)

      {:safe, index_content}
    end
  end

  defp index_file_path do
    Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html")
  end

  # TODO: Find why it's different in dev/prod and during tests
  defp replace_meta(index_content, tags) do
    index_content
    |> String.replace("<meta name=\"server-injected-data\" />", tags)
    |> String.replace("<meta name=server-injected-data>", tags)
  end
end
