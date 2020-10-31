defmodule Mix.Tasks.Mobilizon.Users.Modify do
  @moduledoc """
  Task to modify an existing Mobilizon user
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @shortdoc "Modify a Mobilizon user"

  @impl Mix.Task
  def run([email | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          email: :string,
          disable: :boolean,
          enable: :boolean,
          user: :boolean,
          moderator: :boolean,
          admin: :boolean
        ]
      )

    user? = Keyword.get(options, :user, false)
    moderator? = Keyword.get(options, :moderator, false)
    admin? = Keyword.get(options, :admin, false)
    disable? = Keyword.get(options, :disable, false)
    enable? = Keyword.get(options, :enable, false)
    new_email = Keyword.get(options, :email)

    if disable? && enable? do
      shell_error("Can't use both --enabled and --disable options at the same time.")
    end

    start_mobilizon()

    with {:ok, %User{} = user} <- Users.get_user_by_email(email),
         attrs <- %{},
         role <- calculate_role(admin?, moderator?, user?),
         attrs <- process_new_value(attrs, :mail, new_email, user.email),
         attrs <- process_new_value(attrs, :role, role, user.role),
         attrs <-
           if(disable? && !is_nil(user.confirmed_at),
             do: Map.put(attrs, :confirmed_at, nil),
             else: attrs
           ),
         attrs <-
           if(enable? && is_nil(user.confirmed_at),
             do: Map.put(attrs, :confirmed_at, DateTime.utc_now()),
             else: attrs
           ),
         {:makes_changes, true} <- {:makes_changes, attrs != %{}},
         {:ok, %User{} = user} <- Users.update_user(user, attrs) do
      shell_info("""
      An user has been modified with the following information:
        - email: #{user.email}
        - Role: #{user.role}
        - Activated: #{if user.confirmed_at, do: user.confirmed_at, else: "False"}
      """)
    else
      {:makes_changes, false} ->
        shell_info("No change has been made")

      {:error, :user_not_found} ->
        shell_error("Error: No such user")

      {:error, %Ecto.Changeset{errors: errors}} ->
        shell_error(inspect(errors))
        shell_error("User has not been modified because of the above reason.")

      err ->
        shell_error(inspect(err))
        shell_error("User has not been modified because of an unknown reason.")
    end
  end

  def run(_) do
    shell_error("mobilizon.users.new requires an email as argument")
  end

  @spec process_new_value(map(), atom(), any(), any()) :: map()
  defp process_new_value(attrs, attribute, new_value, old_value) do
    if !is_nil(new_value) && new_value != old_value do
      Map.put(attrs, attribute, new_value)
    else
      attrs
    end
  end

  @spec calculate_role(boolean(), boolean(), boolean()) ::
          :administrator | :moderator | :user | nil
  defp calculate_role(admin?, moderator?, user?) do
    cond do
      admin? -> :administrator
      moderator? -> :moderator
      user? -> :user
      true -> nil
    end
  end
end
