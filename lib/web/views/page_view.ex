defmodule Mobilizon.Web.PageView do
  @moduledoc """
  View for our webapp
  """

  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Tombstone

  alias Mobilizon.Service.Metadata
  alias Mobilizon.Service.Metadata.Instance

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.Convertible
  import Mobilizon.Web.Views.Utils

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

  def render("discussion.activity-json", %{conn: %{assigns: %{object: %Discussion{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resource.activity-json", %{conn: %{assigns: %{object: %Resource{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("post.activity-json", %{conn: %{assigns: %{object: %Post{} = post}}}) do
    post
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render(page, %{object: object, conn: conn} = _assigns)
      when page in ["actor.html", "event.html", "comment.html", "post.html"] do
    with locale <- get_locale(conn),
         tags <- object |> Metadata.build_tags(locale),
         {:ok, html} <- inject_tags(tags, locale) do
      html
    else
      {:error, error} ->
        return_error(conn, error)
    end
  end

  # Discussions are private, no need to embed metadata
  def render("discussion.html", params), do: render("index.html", params)

  def render("index.html", %{conn: conn}) do
    with tags <- Instance.build_tags(),
         {:ok, html} <- inject_tags(tags, get_locale(conn)) do
      html
    else
      {:error, error} ->
        return_error(conn, error)
    end
  end
end
