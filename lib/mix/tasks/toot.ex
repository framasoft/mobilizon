defmodule Mix.Tasks.Toot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  require Logger

  @shortdoc "Toot to an user"
  def run([from, content]) do
    Mix.Task.run("app.start")

    MobilizonWeb.API.Comments.create_comment(from, content)
  end
end
