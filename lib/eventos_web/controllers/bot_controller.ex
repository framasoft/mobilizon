defmodule EventosWeb.BotController do
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.{Bot, Actor}

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    bots = Actors.list_bots()
    render(conn, "index.json", bots: bots)
  end

  def create(conn, %{"bot" => bot_params}) do
    with user <- Guardian.Plug.current_resource(conn),
         bot_params <- Map.put(bot_params, "user_id", user.id),
         %Actor{} = actor <- Actors.register_bot_account(%{name: bot_params["name"], summary: bot_params["summary"]}),
         bot_params <- Map.put(bot_params, "actor_id", actor.id),
         {:ok, %Bot{} = bot} <- Actors.create_bot(bot_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", bot_path(conn, :show, bot))
      |> render("show.json", bot: bot)
    end
  end

  def show(conn, %{"id" => id}) do
    bot = Actors.get_bot!(id)
    render(conn, "show.json", bot: bot)
  end

  def update(conn, %{"id" => id, "bot" => bot_params}) do
    bot = Actors.get_bot!(id)

    with {:ok, %Bot{} = bot} <- Actors.update_bot(bot, bot_params) do
      render(conn, "show.json", bot: bot)
    end
  end

  def delete(conn, %{"id" => id}) do
    bot = Actors.get_bot!(id)
    with {:ok, %Bot{}} <- Actors.delete_bot(bot) do
      send_resp(conn, :no_content, "")
    end
  end
end
