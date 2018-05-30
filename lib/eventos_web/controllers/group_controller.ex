defmodule EventosWeb.GroupController do
  @moduledoc """
  Controller for Groups
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.Actor

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    groups = Actors.list_groups()
    render(conn, EventosWeb.ActorView, "index.json", actors: groups)
  end

  def create(conn, %{"group" => group_params}) do
    with actor_admin = Guardian.Plug.current_resource(conn).actor,
      {:ok, %Actor{} = group} <- Actors.create_group(group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", actor_path(conn, :show, group))
      |> render(EventosWeb.ActorView, "acccount_basic.json", actor: group)
    end
  end
end
