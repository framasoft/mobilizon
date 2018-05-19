defmodule EventosWeb.ActorController do
  @moduledoc """
  Controller for Actors
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.Actor
  alias Eventos.Service.ActivityPub

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    actors = Actors.list_actors()
    render(conn, "index.json", actors: actors)
  end

  def show(conn, %{"name" => name}) do
    actor = Actors.get_actor_by_name_with_everything(name)
    render(conn, "show.json", actor: actor)
  end

  def search(conn, %{"name" => name}) do
    with {:ok, actor} <- ActivityPub.make_actor_from_nickname(name) do
      render(conn, "acccount_basic.json", actor: actor)
    else
      {:error, err} -> json(conn, err)
    end
  end

  def update(conn, %{"name" => name, "actor" => actor_params}) do
    actor = Actors.get_local_actor_by_name(name)

    with {:ok, %Actor{} = actor} <- Actors.update_actor(actor, actor_params) do
      render(conn, "show.json", actor: actor)
    end
  end

#  def delete(conn, %{"id" => id_str}) do
#    {id, _} = Integer.parse(id_str)
#    if Guardian.Plug.current_resource(conn).actor.id == id do
#      actor = Actors.get_actor!(id)
#      with {:ok, %Actor{}} <- Actors.delete_actor(actor) do
#        send_resp(conn, :no_content, "")
#      end
#    else
#      send_resp(conn, 401, "")
#    end
#  end
end
