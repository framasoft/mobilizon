defmodule Mix.Tasks.Mobilizon.Users.Show do
  @moduledoc """
  Task to display an user details
  """
  use Mix.Task
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Actors.Actor

  @shortdoc "Show a Mobilizon user details"

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start")

    with {:ok, %User{} = user} <- Users.get_user_by_email(email),
         actors <- Users.get_actors_for_user(user) do
      Mix.shell().info("""
      Informations for the user #{user.email}:
        - Activated: #{user.confirmed_at}
        - Role: #{user.role}
        #{display_actors(actors)}
      """)
    else
      {:error, :user_not_found} ->
        Mix.raise("Error: No such user")
    end
  end

  def run(_) do
    Mix.raise("mobilizon.users.show requires an email as argument")
  end

  defp display_actors([]), do: ""

  defp display_actors(actors) do
    """
    Identities (#{length(actors)}):
    #{actors |> Enum.map(&display_actor/1) |> Enum.join("")}
    """
  end

  defp display_actor(%Actor{} = actor) do
    """
        - @#{actor.preferred_username} / #{actor.name}
    """
  end
end
