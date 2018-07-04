defmodule Mix.Tasks.CreateBot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  alias Eventos.Actors
  alias Eventos.Actors.Bot
  alias Eventos.Repo
  alias Eventos.Actors.User
  import Logger

  @shortdoc "Register user"
  def run([email, name, summary, type, url]) do
    Mix.Task.run("app.start")

    with {:ok, %User{} = user} <- Actors.find_by_email(email),
      actor <- Actors.register_bot_account(%{name: name, summary: summary}),
      {:ok, %Bot{} = bot} <- Actors.create_bot(%{"type" => type, "source" => url, "actor_id" => actor.id, "user_id" => user.id}) do
      bot

    else
      e -> Logger.error(inspect e)
    end
  end
end
