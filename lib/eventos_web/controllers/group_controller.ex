defmodule EventosWeb.GroupController do
  @moduledoc """
  Controller for Groups
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.{Actor, Member}

  action_fallback(EventosWeb.FallbackController)

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
      |> render(EventosWeb.ActorView, "actor_basic.json", actor: group)
    end
  end

  def join(conn, %{"name" => group_name}) do
    with actor = Guardian.Plug.current_resource(conn).actor,
         group <- Actors.get_group_by_name(group_name),
         %Member{} = member <-
           Actors.create_member(%{"parent_id" => group.id, "actor_id" => actor.id}) do
      conn
      |> put_status(:created)
      |> render(EventosWeb.MemberView, "member.json", member: member)
    else
      err ->
        import Logger
        Logger.debug(inspect(err))
    end
  end
end
