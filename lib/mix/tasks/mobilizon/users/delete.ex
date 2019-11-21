defmodule Mix.Tasks.Mobilizon.Users.Delete do
  @moduledoc """
  Task to delete a user
  """
  use Mix.Task
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @shortdoc "Deletes a Mobilizon user"

  @impl Mix.Task
  def run([email | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          assume_yes: :boolean
        ],
        aliases: [
          y: :assume_yes
        ]
      )

    assume_yes? = Keyword.get(options, :assume_yes, false)

    Mix.Task.run("app.start")

    with {:ok, %User{} = user} <- Users.get_user_by_email(email),
         true <- assume_yes? or Mix.shell().yes?("Continue with deleting user #{user.email}?"),
         {:ok, %User{} = user} <-
           Users.delete_user(user) do
      Mix.shell().info("""
      The user #{user.email} has been deleted
      """)
    else
      {:error, :user_not_found} ->
        Mix.raise("Error: No such user")

      _ ->
        Mix.raise("User has not been deleted.")
    end
  end

  def run(_) do
    Mix.raise("mobilizon.users.delete requires an email as argument")
  end
end
