defmodule Mix.Tasks.Mobilizon.Users.Delete do
  @moduledoc """
  Task to delete a user
  """
  use Mix.Task
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Deletes a Mobilizon user"

  @impl Mix.Task
  def run([email | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          assume_yes: :boolean,
          keep_email: :boolean
        ],
        aliases: [
          y: :assume_yes,
          k: :keep_email
        ]
      )

    assume_yes? = Keyword.get(options, :assume_yes, false)
    keep_email? = Keyword.get(options, :keep_email, false)

    start_mobilizon()

    with {:ok, %User{} = user} <- Users.get_user_by_email(email),
         true <- assume_yes? or shell_yes?("Continue with deleting user #{user.email}?"),
         {:ok, %User{} = user} <-
           Users.delete_user(user, reserve_email: keep_email?) do
      shell_info("""
      The user #{user.email} has been deleted
      """)
    else
      {:error, :user_not_found} ->
        shell_error("Error: No such user")

      _ ->
        shell_error("User has not been deleted.")
    end
  end

  def run(_) do
    shell_error("mobilizon.users.delete requires an email as argument")
  end
end
