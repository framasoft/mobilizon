defmodule Mix.Tasks.Mobilizon.Users.New do
  @moduledoc """
  Task to create a new user
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  import Mix.Tasks.Mobilizon.Actors.Utils
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Auth.Authenticator
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
          profile_display_name: :string,
          provider: :string
        ],
        aliases: [
          p: :password
        ]
      )

    start_mobilizon()

    password =
      Keyword.get(
        options,
        :password,
        :crypto.strong_rand_bytes(16) |> Base.encode64() |> binary_part(0, 16)
      )

    provider = Keyword.get(options, :provider)

    case create_user(email, provider, password, options) do
      {:ok, %User{} = user} ->
        profile = maybe_create_profile(user, options)

        shell_info("""
        An user has been created with the following information:
          - email: #{user.email}
          - password: #{if is_nil(provider), do: password, else: "Your #{provider} password"}
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

  @spec create_user(String.t(), String.t() | nil, String.t(), Keyword.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp create_user(email, provider, password, options) do
    role = get_role(options)

    if is_nil(provider) do
      create_database_user(email, password, role)
    else
      check_password_and_provider_options(options)

      if provider != nil && provider != Authenticator.provider_name() do
        shell_info("""
        Warning: The #{provider} provider isn't currently configured as default authenticator.
        """)
      end

      create_user_from_provider(email, provider, role)
    end
  end

  @spec create_database_user(String.t(), String.t(), role()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp create_database_user(email, password, role) do
    Users.register(%{
      email: email,
      password: password,
      role: role,
      confirmed_at: DateTime.utc_now(),
      confirmation_sent_at: nil,
      confirmation_token: nil
    })
  end

  @spec create_user_from_provider(String.t(), String.t(), role()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp create_user_from_provider(email, provider, role) do
    Users.create_external(email, provider, %{role: role})
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

  @type role :: :administrator | :moderator | :user

  @spec get_role(Keyword.t()) :: role()
  defp get_role(options) do
    moderator? = Keyword.get(options, :moderator, false)
    admin? = Keyword.get(options, :admin, false)

    cond do
      admin? -> :administrator
      moderator? -> :moderator
      true -> :user
    end
  end

  @spec check_password_and_provider_options(Keyword.t()) :: nil | no_return()
  defp check_password_and_provider_options(options) do
    if Keyword.get(options, :password) != nil && Keyword.get(options, :provider) != nil do
      shell_error("""
      The --password and --provider options can't be specified at the same time.
      """)
    end
  end
end
