#defmodule EventosWeb.GroupController do
#  @moduledoc """
#  Controller for Groups
#  """
#  use EventosWeb, :controller
#
#  alias Eventos.Actors
#  alias Eventos.Actors.Actor
#
#  action_fallback EventosWeb.FallbackController
#
#  def index(conn, _params) do
#    groups = Actors.list_groups()
#    render(conn, "index.json", groups: groups)
#  end
#
#  def create(conn, %{"group" => group_params}) do
#    group_params = Map.put(group_params, "url", "h")
#    with {:ok, %Group{} = group} <- Actors.create_group(group_params) do
#      conn
#      |> put_status(:created)
#      |> put_resp_header("location", group_path(conn, :show, group))
#      |> render("show_simple.json", group: group)
#    end
#  end
#
#  def show(conn, %{"id" => id}) do
#    group = Actors.get_group_full!(id)
#    render(conn, "show.json", group: group)
#  end
#
#  def update(conn, %{"id" => id, "group" => group_params}) do
#    group = Actors.get_group!(id)
#
#    with {:ok, %Actor{} = group} <- Actors.update_group(group, group_params) do
#      render(conn, "show_simple.json", group: group)
#    end
#  end
#
#  def delete(conn, %{"id" => id}) do
#    group = Actors.get_group!(id)
#    with {:ok, %Actor{}} <- Actors.delete_group(group) do
#      send_resp(conn, :no_content, "")
#    end
#  end
#end
