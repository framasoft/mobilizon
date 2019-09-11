defmodule Mix.Tasks.Mobilizon.CreateBot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  alias Mobilizon.Actors
  alias Mobilizon.Users
  alias Mobilizon.Actors.Bot
  alias Mobilizon.Users.User
  require Logger

  @shortdoc "Register user"
  def run([email, name, summary, type, url]) do
    Mix.Task.run("app.start")

    with {:ok, %User{} = user} <- Users.get_user_by_email(email, true),
         actor <- Actors.register_bot(%{name: name, summary: summary}),
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
