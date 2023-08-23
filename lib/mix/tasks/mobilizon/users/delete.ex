defmodule Mix.Tasks.Mobilizon.Users.Delete do
  @moduledoc """
  Task to delete a user
  """
  use Mix.Task
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Federation.ActivityPub.Actions.Delete
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Deletes a Mobilizon user or multiple users matching a pattern"

  @impl Mix.Task
  def run(argv) do
    {options, args, []} =
      OptionParser.parse(
        argv,
        strict: [
          assume_yes: :boolean,
          all_matching_email_domain: :boolean,
          all_matching_ip: :boolean,
          include_groups_where_admin: :boolean,
          keep_email: :boolean,
          help: :boolean
        ],
        aliases: [
          h: :help,
          k: :keep_email,
          y: :assume_yes
        ]
      )

    if Keyword.get(options, :help, false) do
      show_help()
    end

    if Enum.empty?(args) do
      shell_error("mobilizon.users.delete requires an email as argument")
    end

    all_matching_ip? = Keyword.get(options, :all_matching_ip, false)

    if Keyword.get(options, :all_matching_email_domain, false) and all_matching_ip? do
      shell_error(
        "Can't use options --all_matching_email_domain and --all_matching_ip options at the same time"
      )
    end

    input = String.trim(hd(args))

    if all_matching_ip? and not valid_ip?(input) do
      shell_error("Provided IP address is not a valid format")
    end

    start_mobilizon()

    handle_command(input, options)
  end

  @spec handle_command(String.t(), Keyword.t()) :: any()
  defp handle_command(input, options) do
    cond do
      Keyword.get(options, :all_matching_email_domain, false) ->
        delete_users_matching_email_domain(input, options)

      Keyword.get(options, :all_matching_ip, false) ->
        delete_users_matching_ip(input, options)

      String.contains?(input, "@") ->
        delete_single_user(input, options)

      true ->
        shell_error("Provided input does not seem to be an email address")
    end
  end

  defp delete_single_user(input, options) do
    with {:ok, %User{} = user} <- Users.get_user_by_email(input),
         true <-
           Keyword.get(options, :assume_yes, false) or
             shell_yes?("Continue with deleting user #{user.email}?") do
      do_delete_users([user], options)

      shell_info("""
      The user #{user.email} has been deleted
      """)
    else
      {:error, :user_not_found} ->
        shell_error("No user with the email \"#{input}\" was found")

      _ ->
        shell_error("User has not been deleted.")
    end
  end

  defp delete_users_matching_email_domain(input, options) do
    users = Users.get_users_by_email_domain(input)
    nb_users = length(users)
    assume_yes? = Keyword.get(options, :assume_yes, false)

    with {:no_users, false} <- {:no_users, nb_users == 0},
         {:confirm, true} <-
           {:confirm, assume_yes? or shell_yes?("Continue with deleting #{length(users)} users?")},
         true <-
           do_delete_users(users, options) do
      shell_info("""
      All users from domain #{input} have been deleted
      """)
    else
      {:no_users, true} ->
        shell_error("No users found for this email domain")

      {:confirm, false} ->
        shell_error("Users have not been deleted.")
    end
  end

  defp delete_users_matching_ip(input, options) do
    users = Users.get_users_by_ip_address(input)
    nb_users = length(users)
    assume_yes? = Keyword.get(options, :assume_yes, false)

    with {:no_users, false} <- {:no_users, nb_users == 0},
         {:confirm, true} <-
           {:confirm, assume_yes? or shell_yes?("Continue with deleting #{length(users)} users?")},
         true <-
           do_delete_users(users, options) do
      shell_info("""
      All users using IP address #{input} have been deleted
      """)
    else
      {:no_users, true} ->
        shell_error("No users found for this IP address")

      {:confirm, false} ->
        shell_error("Users have not been deleted.")
    end
  end

  defp do_delete_users(users, options) do
    Enum.each(users, fn user -> do_delete_user(user, options) end)
    true
  end

  defp do_delete_user(user, options) do
    with actors <- Users.get_actors_for_user(user),
         # Detach actors from user
         :ok <- Enum.each(actors, fn actor -> Actors.update_actor(actor, %{user_id: nil}) end),
         # Launch a background job to delete actors
         :ok <-
           Enum.each(actors, fn actor ->
             # Delete groups the actor is an admin for
             if Keyword.get(options, :include_groups_where_admin, false) do
               suspend_group_where_admin(actor)
             end

             Delete.delete(actor, actor, true)
           end) do
      # Delete user
      Users.delete_user(user, reserve_email: Keyword.get(options, :keep_email, false))
    end
  end

  defp suspend_group_where_admin(actor) do
    %Page{elements: memberships} = Actors.list_memberships_for_user(actor.user_id, nil, 1, 10_000)

    memberships
    |> Enum.filter(fn membership -> membership.role === :administrator end)
    |> Enum.each(fn membership ->
      Delete.delete(membership.parent, actor, true)
    end)
  end

  @ip_regex ~r/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$|^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/

  @spec valid_ip?(String.t()) :: boolean()
  defp valid_ip?(ip) do
    String.match?(ip, @ip_regex)
  end

  defp show_help do
    shell_info("""
    mobilizon.users.delete [-y/--assume-yes] [--all-matching-email-domain] [--all-matching-ip] [--include-groups-where-admin] [-h/--help] [email/domain/ip]

    This command allows to delete a single user or multiple users using their email domain or IP address properties. Actors are suspended as well.

    Options:

      --all-matching-email-domain
              Delete all users matching the given input as email domain

      --all-matching-ip
              Delete all users matching the given input as email domain

      -k/--keep-email
              Keep a record of the email in the users table so that the email can't be used to register again

      -h/--help
              Show the help

      --include-groups-where-admin
              Also suspend groups of which the user's actor profiles were admin of

      -y/--assume-yes
              Automatically answer yes for all questions.
    """)

    shutdown(error_code: 0)
  end
end
