defmodule Mix.Tasks.CreateBot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Bot
  alias Mobilizon.Repo
  alias Mobilizon.Actors.User
  import Logger

  @shortdoc "Register user"
  def run([email, name, summary, type, url]) do
    Mix.Task.run("app.start")

    with {:ok, %User{} = user} <- Actors.get_user_by_email(email, true),
         actor <- Actors.register_bot_account(%{name: name, summary: summary}),
         {:ok, %Bot{} = bot} <-
           Actors.create_bot(%{
             "type" => type,
             "source" => url,
             "actor_id" => actor.id,
             "user_id" => user.id
           }) do
      bot
    else
      e -> Logger.error(inspect(e))
    end
  end
end
