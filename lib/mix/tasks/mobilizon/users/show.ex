defmodule Mix.Tasks.Mobilizon.Users.Show do
  @moduledoc """
  Task to display an user details
  """

  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @shortdoc "Show a Mobilizon user details"

  @impl Mix.Task
  def run([email]) do
    start_mobilizon()

    with {:ok, %User{} = user} <- Users.get_user_by_email(email),
         actors <- Users.get_actors_for_user(user) do
      shell_info("""
      Informations for the user #{user.email}:
        - Activated: #{user.confirmed_at}
        - Disabled: #{user.disabled}
        - Role: #{user.role}
        #{display_actors(actors)}
      """)
    else
      {:error, :user_not_found} ->
        shell_error("Error: No such user")
    end
  end

  def run(_) do
    shell_error("mobilizon.users.show requires an email as argument")
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
