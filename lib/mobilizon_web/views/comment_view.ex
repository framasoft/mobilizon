defmodule MobilizonWeb.CommentView do
  use MobilizonWeb, :view
  alias MobilizonWeb.CommentView

  def render("index.json", %{comments: comments}) do
    %{data: render_many(comments, CommentView, "comment.json")}
  end

  def render("show.json", %{comment: comment}) do
    %{data: render_one(comment, CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{id: comment.id, uuid: comment.uuid, url: comment.url, text: comment.text}
  end
end
