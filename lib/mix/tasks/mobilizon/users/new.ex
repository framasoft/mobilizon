defmodule Mix.Tasks.Mobilizon.Users.New do
  @moduledoc """
  Task to create a new user
  """
  use Mix.Task
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run([email | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          password: :string,
          moderator: :boolean,
          admin: :boolean
        ],
        aliases: [
          p: :password
        ]
      )

    moderator? = Keyword.get(options, :moderator, false)
    admin? = Keyword.get(options, :admin, false)

    role =
      cond do
        admin? -> :administrator
        moderator? -> :moderator
        true -> :user
      end

    password =
      Keyword.get(
        options,
        :password,
        :crypto.strong_rand_bytes(16) |> Base.encode64() |> binary_part(0, 16)
      )

    Mix.Task.run("app.start")

    case Users.register(%{
           email: email,
           password: password,
           role: role,
           confirmed_at: DateTime.utc_now(),
           confirmation_sent_at: nil,
           confirmation_token: nil
         }) do
      {:ok, %User{} = user} ->
        Mix.shell().info("""
        An user has been created with the following information:
          - email: #{user.email}
          - password: #{password}
          - Role: #{user.role}
        The user will be prompted to create a new profile after login for the first time.
        """)

      {:error, %Ecto.Changeset{errors: errors}} ->
        Mix.shell().error(inspect(errors))
        Mix.raise("User has not been created because of the above reason.")

      err ->
        Mix.shell().error(inspect(err))
        Mix.raise("User has not been created because of an unknown reason.")
    end
  end

  def run(_) do
    Mix.raise("mobilizon.users.new requires an email as argument")
  end
end
