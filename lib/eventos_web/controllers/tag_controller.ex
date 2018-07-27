defmodule EventosWeb.TagController do
  @moduledoc """
  Controller for Tags
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.Tag

  action_fallback(EventosWeb.FallbackController)

  def index(conn, _params) do
    tags = Events.list_tags()
    render(conn, "index.json", tags: tags)
  end

  def create(conn, %{"tag" => tag_params}) do
    with {:ok, %Tag{} = tag} <- Events.create_tag(tag_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", tag_path(conn, :show, tag))
      |> render("show.json", tag: tag)
    end
  end

  def show(conn, %{"id" => id}) do
    tag = Events.get_tag!(id)
    render(conn, "show.json", tag: tag)
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    tag = Events.get_tag!(id)

    with {:ok, %Tag{} = tag} <- Events.update_tag(tag, tag_params) do
      render(conn, "show.json", tag: tag)
    end
  end

  def delete(conn, %{"id" => id}) do
    tag = Events.get_tag!(id)

    with {:ok, %Tag{}} <- Events.delete_tag(tag) do
      send_resp(conn, :no_content, "")
    end
  end
end
