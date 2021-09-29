defmodule Mix.Tasks.Mobilizon.Actors.New do
  @moduledoc """
  Task to create a new user
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Actors.Utils
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Users.User

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(rest) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          email: :string,
          username: :string,
          display_name: :string,
          group_admin: :string,
          type: :string
        ],
        aliases: [
          e: :email,
          u: :username,
          d: :display_name,
          t: :type,
          a: :group_admin
        ]
      )

    start_mobilizon()

    profile_username = Keyword.get(options, :username)
    profile_name = Keyword.get(options, :display_name)

    if profile_name != nil || profile_username != nil do
    else
      shell_error("You need to provide at least --username or --display-name.")
    end

    case Keyword.get(options, :type, "profile") do
      "profile" ->
        do_create_profile(options, profile_username, profile_name)

      "group" ->
        do_create_group(options, profile_username, profile_name)
    end
  end

  @spec do_create_profile(Keyword.t(), String.t(), String.t()) :: Actor.t() | nil
  defp do_create_profile(options, profile_username, profile_name) do
    with {:email, email} when is_binary(email) <- {:email, Keyword.get(options, :email)},
         {:ok, %User{} = user} <- Users.get_user_by_email(email),
         %Actor{preferred_username: preferred_username, name: name} <-
           create_profile(user, profile_username, profile_name, default: false) do
      shell_info("""
      A profile was created for user #{email} with the following information:
      - username: #{preferred_username}
      - display name: #{name}
      """)
    else
      {:email, nil} ->
        shell_error("You need to provide an email for creating a new profile.")

      {:error, :user_not_found} ->
        shell_error("No user with this email was found.")

      nil ->
        nil
    end
  end

  defp do_create_group(options, profile_username, profile_name) do
    with {:option, admin_name} when is_binary(admin_name) <-
           {:option, Keyword.get(options, :group_admin)},
         {:admin, %Actor{} = admin} <- {:admin, Actors.get_local_actor_by_name(admin_name)},
         {:ok, %Actor{preferred_username: preferred_username, name: name}} <-
           create_group(admin, profile_username, profile_name) do
      shell_info("""
      A group was created with profile #{admin_name} as the admin and with the following information:
      - username: #{preferred_username}
      - display name: #{name}
      """)
    else
      {:option, nil} ->
        shell_error(
          "You need to provide --group-admin with the username of the admin to create a group."
        )

      {:admin, nil} ->
        shell_error("Profile with username #{Keyword.get(options, :group_admin)} wasn't found")

      {:error, %Ecto.Changeset{errors: errors}} ->
        shell_error(inspect(errors))
        shell_error("Error while creating group because of the above reason")
    end
  end
end
