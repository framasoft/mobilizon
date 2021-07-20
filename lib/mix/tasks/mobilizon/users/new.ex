defmodule Mix.Tasks.Mobilizon.Users.New do
  @moduledoc """
  Task to create a new user
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  import Mix.Tasks.Mobilizon.Actors.Utils
  alias Mobilizon.Actors.Actor
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
          admin: :boolean,
          profile_username: :string,
          profile_display_name: :string
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

    start_mobilizon()

    case Users.register(%{
           email: email,
           password: password,
           role: role,
           confirmed_at: DateTime.utc_now(),
           confirmation_sent_at: nil,
           confirmation_token: nil
         }) do
      {:ok, %User{} = user} ->
        profile = maybe_create_profile(user, options)

        shell_info("""
        An user has been created with the following information:
          - email: #{user.email}
          - password: #{password}
          - Role: #{user.role}
        """)

        if is_nil(profile) do
          shell_info("""
          The user will be prompted to create a new profile after login for the first time.
          """)
        else
          shell_info("""
          A profile was added with the following information:
          - username: #{profile.preferred_username}
          - display name: #{profile.name}
          """)
        end

      {:error, %Ecto.Changeset{errors: errors}} ->
        shell_error(inspect(errors))
        shell_error("User has not been created because of the above reason.")

      err ->
        shell_error(inspect(err))
        shell_error("User has not been created because of an unknown reason.")
    end
  end

  def run(_) do
    shell_error("mobilizon.users.new requires an email as argument")
  end

  @spec maybe_create_profile(User.t(), Keyword.t()) :: Actor.t() | nil
  defp maybe_create_profile(%User{} = user, options) do
    profile_username = Keyword.get(options, :profile_username)
    profile_name = Keyword.get(options, :profile_display_name)

    if profile_name != nil || profile_username != nil do
      create_profile(user, profile_username, profile_name)
    else
      nil
    end
  end
end
