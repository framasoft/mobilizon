defmodule MobilizonWeb.GroupController do
  @moduledoc """
  Controller for Groups
  """
  use MobilizonWeb, :controller

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}

  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params) do
    groups = Actors.list_groups()
    render(conn, MobilizonWeb.ActorView, "index.json", actors: groups)
  end

  def create(conn, %{"group" => group_params}) do
    with {:ok, %Actor{} = group} <- Actors.create_group(group_params),
         {:ok, %Member{} = member} <-
           Actors.create_member(%{
             "parent_id" => group.id,
             "actor_id" => Actors.get_local_actor_by_name(group_params["actor_admin"]).id,
             "role" => 2
           }) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", actor_path(conn, :show, group))
      |> render(MobilizonWeb.ActorView, "actor_basic.json", actor: group)
    end
  end

  def join(conn, %{"name" => group_name, "actor_name" => actor_name}) do
    with %Actor{} = group <- Actors.get_group_by_name(group_name),
         %Actor{} = actor <- Actors.get_local_actor_by_name(actor_name),
         {:ok, %Member{} = member} <-
           Actors.create_member(%{"parent_id" => group.id, "actor_id" => actor.id}) do
      conn
      |> put_status(:created)
      |> render(MobilizonWeb.MemberView, "member.json", member: member)
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> render(MobilizonWeb.ErrorView, "not_found.json",
          details: "group or actor doesn't exist"
        )

      err ->
        require Logger
        Logger.debug(inspect(err))
    end
  end
end
