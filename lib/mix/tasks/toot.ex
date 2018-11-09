defmodule Mix.Tasks.Toot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Repo
  alias Mobilizon.Events
  alias Mobilizon.Events.Comment
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils
  require Logger

  @shortdoc "Toot to an user"
  def run([from, to, content]) do
    Mix.Task.run("app.start")

    with %Actor{} = from <- Actors.get_actor_by_name(from),
         {:ok, %Actor{} = to} <- ActivityPub.find_or_make_actor_from_nickname(to),
         context <- Utils.make_context(nil) do
      comment = Utils.make_comment_data(from.url, [to.url], context, content)

      ActivityPub.create(%{
        to: [to.url],
        actor: from,
        object: comment,
        context: context,
        local: true
      })
    else
      e -> Logger.error(inspect(e))
    end
  end
end
