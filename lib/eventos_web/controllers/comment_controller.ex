defmodule EventosWeb.CommentController do
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.Comment

  action_fallback(EventosWeb.FallbackController)

  def index(conn, _params) do
    comments = Events.list_comments()
    render(conn, "index.json", comments: comments)
  end

  def create(conn, %{"comment" => comment_params}) do
    with {:ok, %Comment{} = comment} <- Events.create_comment(comment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", comment_path(conn, :show, comment))
      |> render("show.json", comment: comment)
    end
  end

  def show(conn, %{"uuid" => uuid}) do
    comment = Events.get_comment_with_uuid!(uuid)
    render(conn, "show.json", comment: comment)
  end

  def update(conn, %{"uuid" => uuid, "comment" => comment_params}) do
    comment = Events.get_comment_with_uuid!(uuid)

    with {:ok, %Comment{} = comment} <- Events.update_comment(comment, comment_params) do
      render(conn, "show.json", comment: comment)
    end
  end

  def delete(conn, %{"uuid" => uuid}) do
    comment = Events.get_comment_with_uuid!(uuid)

    with {:ok, %Comment{}} <- Events.delete_comment(comment) do
      send_resp(conn, :no_content, "")
    end
  end
end
