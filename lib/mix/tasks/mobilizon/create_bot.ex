defmodule Mix.Tasks.Mobilizon.CreateBot do
  @moduledoc """
  Creates a bot from a source.
  """

  use Mix.Task

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Bot
  alias Mobilizon.Users.User
  import Mix.Tasks.Mobilizon.Common

  require Logger

  @shortdoc "Create bot"
  def run([email, name, summary, type, url]) do
    start_mobilizon()

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
      error ->
        Logger.error(inspect(error))
    end
  end
end
