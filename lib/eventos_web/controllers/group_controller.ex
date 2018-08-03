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
    with {:ok, %Actor{} = group} <- Actors.create_group(group_params) do
      %Member{} =
        _member =
        Actors.create_member(%{
          "parent_id" => group.id,
          "actor_id" => Actors.get_local_actor_by_name(group_params["actor_admin"]).id,
          "role" => 2
        })

      conn
      |> put_status(:created)
      |> put_resp_header("location", actor_path(conn, :show, group))
      |> render(EventosWeb.ActorView, "actor_basic.json", actor: group)
    end
  end

  def join(conn, %{"name" => group_name, "actor_name" => actor_name}) do
    with %Actor{} = group <- Actors.get_group_by_name(group_name),
         %Actor{} = actor <- Actors.get_local_actor_by_name(actor_name),
         %Member{} = member <-
           Actors.create_member(%{"parent_id" => group.id, "actor_id" => actor.id}) do
      conn
      |> put_status(:created)
      |> render(EventosWeb.MemberView, "member.json", member: member)
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> render(EventosWeb.ErrorView, "not_found.json", details: "group or actor doesn't exist")
      err ->
        require Logger
        Logger.debug(inspect(err))
    end
  end
end
