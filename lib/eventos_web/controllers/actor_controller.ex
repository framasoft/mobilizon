defmodule EventosWeb.ActorController do
  @moduledoc """
  Controller for Actors
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.{Actor, User}
  alias Eventos.Service.ActivityPub

  action_fallback(EventosWeb.FallbackController)

  def index(conn, _params) do
    actors = Actors.list_actors()
    render(conn, "index.json", actors: actors)
  end

  def create(conn, %{"actor" => actor_params}) do
    with %User{} = user <- Guardian.Plug.current_resource(conn),
         actor_params <- Map.put(actor_params, "user_id", user.id),
         actor_params <- Map.put(actor_params, "keys", keys_for_account()),
         {:ok, %Actor{} = actor} <- Actors.create_actor(actor_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", actor_path(conn, :show, actor.preferred_username))
      |> render("show_basic.json", actor: actor)
    end
  end

  defp keys_for_account() do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)

    [entry]
    |> :public_key.pem_encode()
    |> String.trim_trailing()
  end

  def show(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_actor_by_name_with_everything(name) do
      render(conn, "show.json", actor: actor)
    else
      nil ->
        send_resp(conn, :not_found, "")
    end
  end

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  def search(conn, %{"name" => name}) do
    # find already saved accounts
    case Actors.search(name) do
      {:ok, actors} ->
        render(conn, "index.json", actors: actors)

      {:error, err} ->
        json(conn, err)
    end
  end

  def update(conn, %{"name" => name, "actor" => actor_params}) do
    actor = Actors.get_local_actor_by_name(name)

    with {:ok, %Actor{} = actor} <- Actors.update_actor(actor, actor_params) do
      render(conn, "show_basic.json", actor: actor)
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
