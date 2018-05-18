defmodule EventosWeb.ActorController do
  @moduledoc """
  Controller for Actors
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.Actor

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    actors = Actors.list_actors()
    render(conn, "index.json", actors: actors)
  end

  def show(conn, %{"id" => id}) do
    actor = Actors.get_actor_with_everything!(id)
    render(conn, "show.json", actor: actor)
  end

  def update(conn, %{"id" => id, "actor" => actor_params}) do
    actor = Actors.get_actor!(id)

    with {:ok, %Actor{} = actor} <- Actors.update_actor(actor, actor_params) do
      render(conn, "show.json", actor: actor)
    end
  end

  def delete(conn, %{"id" => id_str}) do
    {id, _} = Integer.parse(id_str)
    if Guardian.Plug.current_resource(conn).actor.id == id do
      actor = Actors.get_actor!(id)
      with {:ok, %Actor{}} <- Actors.delete_actor(actor) do
        send_resp(conn, :no_content, "")
      end
    else
      send_resp(conn, 401, "")
    end
  end
end
