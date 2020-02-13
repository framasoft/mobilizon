defmodule Mobilizon.GraphQL.Resolvers.User do
  @moduledoc """
  Handles the user-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Config, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Crypto
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User

  alias Mobilizon.Web.{Auth, Email}

  require Logger

  @confirmation_token_length 30

  @doc """
  Find an user by its ID
  """
  def find_user(_parent, %{id: id}, _resolution) do
    Users.get_user_with_actors(id)
  end

  @doc """
  Return current logged-in user
  """
  def get_current_user(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def get_current_user(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to view current user"}
  end

  @doc """
  List instance users
  """
  def list_and_count_users(
        _parent,
        %{page: page, limit: limit, sort: sort, direction: direction},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    total = Task.async(&Users.count_users/0)
    elements = Task.async(fn -> Users.list_users(page, limit, sort, direction) end)

    {:ok, %{total: Task.await(total), elements: Task.await(elements)}}
  end

  def list_and_count_users(_parent, _args, _resolution) do
    {:error, "You need to have admin access to list users"}
  end

  @doc """
  Login an user. Returns a token and the user
  """
  def login_user(_parent, %{email: email, password: password}, _resolution) do
    with {:ok, %User{confirmed_at: %DateTime{}} = user} <- Users.get_user_by_email(email),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Users.authenticate(%{user: user, password: password}) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}}
    else
      {:ok, %User{confirmed_at: nil} = _user} ->
        {:error, "User account not confirmed"}

      {:error, :user_not_found} ->
        {:error, "No user with this email was found"}

      {:error, :unauthorized} ->
        {:error, "Impossible to authenticate, either your email or password are invalid."}
    end
  end

  @doc """
  Refresh a token
  """
  def refresh_token(_parent, %{refresh_token: refresh_token}, _context) do
    with {:ok, user, _claims} <- Auth.Guardian.resource_from_token(refresh_token),
         {:ok, _old, {exchanged_token, _claims}} <-
           Auth.Guardian.exchange(refresh_token, ["access", "refresh"], "access"),
         {:ok, refresh_token} <- Users.generate_refresh_token(user) do
      {:ok, %{access_token: exchanged_token, refresh_token: refresh_token}}
    else
      {:error, message} ->
        Logger.debug("Cannot refresh user token: #{inspect(message)}")
        {:error, "Cannot refresh the token"}
    end
  end

  def refresh_token(_parent, _params, _context) do
    {:error, "You need to have an existing token to get a refresh token"}
  end

  @doc """
  Register an user:
    - check registrations are enabled
    - create the user
    - send a validation email to the user
  """
  @spec create_user(any, map, any) :: tuple
  def create_user(_parent, args, _resolution) do
    with :registration_ok <- check_registration_config(args),
         {:ok, %User{} = user} <- Users.register(args) do
      Email.User.send_confirmation_email(user, Map.get(args, :locale, "en"))
      {:ok, user}
    else
      :registration_closed ->
        {:error, "Registrations are not enabled"}

      :not_whitelisted ->
        {:error, "Your email is not on the whitelist"}

      error ->
        error
    end
  end

  @spec check_registration_config(map) :: atom
  defp check_registration_config(%{email: email}) do
    cond do
      Config.instance_registrations_open?() ->
        :registration_ok

      Config.instance_registrations_whitelist?() ->
        check_white_listed_email?(email)

      true ->
        :registration_closed
    end
  end

  @spec check_white_listed_email?(String.t()) :: :registration_ok | :not_whitelisted
  defp check_white_listed_email?(email) do
    [_, domain] = String.split(email, "@", parts: 2, trim: true)

    if domain in Config.instance_registrations_whitelist() or
         email in Config.instance_registrations_whitelist(),
       do: :registration_ok,
       else: :not_whitelisted
  end

  @doc """
  Validate an user, get its actor and a token
  """
  def validate_user(_parent, %{token: token}, _resolution) do
    with {:check_confirmation_token, {:ok, %User{} = user}} <-
           {:check_confirmation_token, Email.User.check_confirmation_token(token)},
         {:get_actor, actor} <- {:get_actor, Users.get_actor_for_user(user)},
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Users.generate_tokens(user) do
      {:ok,
       %{
         access_token: access_token,
         refresh_token: refresh_token,
         user: Map.put(user, :default_actor, actor)
       }}
    else
      error ->
        Logger.info("Unable to validate user with token #{token}")
        Logger.debug(inspect(error))

        {:error, "Unable to validate user"}
    end
  end

  @doc """
  Send the confirmation email again.
  We only do this to accounts unconfirmed
  """
  def resend_confirmation_email(_parent, args, _resolution) do
    with {:ok, %User{locale: locale} = user} <-
           Users.get_user_by_email(Map.get(args, :email), false),
         {:ok, email} <-
           Email.User.resend_confirmation_email(user, Map.get(args, :locale, locale)) do
      {:ok, email}
    else
      {:error, :user_not_found} ->
        {:error, "No user to validate with this email was found"}

      {:error, :email_too_soon} ->
        {:error, "You requested again a confirmation email too soon"}
    end
  end

  @doc """
  Send an email to reset the password from an user
  """
  def send_reset_password(_parent, args, _resolution) do
    with email <- Map.get(args, :email),
         {:ok, %User{locale: locale} = user} <- Users.get_user_by_email(email, true),
         {:ok, %Bamboo.Email{} = _email_html} <-
           Email.User.send_password_reset_email(user, Map.get(args, :locale, locale)) do
      {:ok, email}
    else
      {:error, :user_not_found} ->
        # TODO : implement rate limits for this endpoint
        {:error, "No user with this email was found"}

      {:error, :email_too_soon} ->
        {:error, "You requested again a confirmation email too soon"}
    end
  end

  @doc """
  Reset the password from an user
  """
  def reset_password(_parent, %{password: password, token: token}, _resolution) do
    with {:ok, %User{} = user} <-
           Email.User.check_reset_password_token(password, token),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Users.authenticate(%{user: user, password: password}) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}}
    end
  end

  @doc "Change an user default actor"
  def change_default_actor(
        _parent,
        %{preferred_username: username},
        %{context: %{current_user: user}}
      ) do
    with %Actor{id: actor_id} <- Actors.get_local_actor_by_name(username),
         {:user_actor, true} <-
           {:user_actor, actor_id in Enum.map(Users.get_actors_for_user(user), & &1.id)},
         %User{} = user <- Users.update_user_default_actor(user.id, actor_id) do
      {:ok, user}
    else
      {:user_actor, _} ->
        {:error, :actor_not_from_user}

      _error ->
        {:error, :unable_to_change_default_actor}
    end
  end

  @doc """
  Returns the list of events for all of this user's identities are going to
  """
  def user_participations(
        %User{id: user_id},
        args,
        %{context: %{current_user: %User{id: logged_user_id}}}
      ) do
    with true <- user_id == logged_user_id,
         participations <-
           Events.list_participations_for_user(
             user_id,
             Map.get(args, :after_datetime),
             Map.get(args, :before_datetime),
             Map.get(args, :page),
             Map.get(args, :limit)
           ) do
      {:ok, participations}
    end
  end

  @doc """
  Returns the list of draft events for the current user
  """
  def user_drafted_events(
        %User{id: user_id},
        args,
        %{context: %{current_user: %User{id: logged_user_id}}}
      ) do
    with {:same_user, true} <- {:same_user, user_id == logged_user_id},
         events <-
           Events.list_drafts_for_user(user_id, Map.get(args, :page), Map.get(args, :limit)) do
      {:ok, events}
    end
  end

  def change_password(
        _parent,
        %{old_password: old_password, new_password: new_password},
        %{context: %{current_user: %User{password_hash: old_password_hash} = user}}
      ) do
    with {:current_password, true} <-
           {:current_password, Argon2.verify_pass(old_password, old_password_hash)},
         {:same_password, false} <- {:same_password, old_password == new_password},
         {:ok, %User{} = user} <-
           user
           |> User.password_change_changeset(%{"password" => new_password})
           |> Repo.update() do
      {:ok, user}
    else
      {:current_password, false} ->
        {:error, "The current password is invalid"}

      {:same_password, true} ->
        {:error, "The new password must be different"}

      {:error, %Ecto.Changeset{errors: [password: {"registration.error.password_too_short", _}]}} ->
        {:error,
         "The password you have chosen is too short. Please make sure your password contains at least 6 characters."}
    end
  end

  def change_password(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to change your password"}
  end

  def change_email(_parent, %{email: new_email, password: password}, %{
        context: %{current_user: %User{email: old_email, password_hash: password_hash} = user}
      }) do
    with {:current_password, true} <-
           {:current_password, Argon2.verify_pass(password, password_hash)},
         {:same_email, false} <- {:same_email, new_email == old_email},
         {:email_valid, true} <- {:email_valid, Email.Checker.valid?(new_email)},
         {:ok, %User{} = user} <-
           user
           |> User.changeset(%{
             unconfirmed_email: new_email,
             confirmation_token: Crypto.random_string(@confirmation_token_length),
             confirmation_sent_at: DateTime.utc_now() |> DateTime.truncate(:second)
           })
           |> Repo.update() do
      user
      |> Email.User.send_email_reset_old_email()
      |> Email.Mailer.deliver_later()

      user
      |> Email.User.send_email_reset_new_email()
      |> Email.Mailer.deliver_later()

      {:ok, user}
    else
      {:current_password, false} ->
        {:error, "The password provided is invalid"}

      {:same_email, true} ->
        {:error, "The new email must be different"}

      {:email_valid, _} ->
        {:error, "The new email doesn't seem to be valid"}
    end
  end

  def change_email(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to change your email"}
  end

  def validate_email(_parent, %{token: token}, _resolution) do
    with %User{} = user <- Users.get_user_by_activation_token(token),
         {:ok, %User{} = user} <-
           user
           |> User.changeset(%{
             email: user.unconfirmed_email,
             unconfirmed_email: nil,
             confirmation_token: nil,
             confirmation_sent_at: nil
           })
           |> Repo.update() do
      {:ok, user}
    end
  end

  def delete_account(_parent, %{password: password}, %{
        context: %{current_user: %User{password_hash: password_hash} = user}
      }) do
    with {:current_password, true} <-
           {:current_password, Argon2.verify_pass(password, password_hash)},
         actors <- Users.get_actors_for_user(user),
         # Detach actors from user
         :ok <- Enum.each(actors, fn actor -> Actors.update_actor(actor, %{user_id: nil}) end),
         # Launch a background job to delete actors
         :ok <- Enum.each(actors, &Actors.delete_actor/1),
         # Delete user
         {:ok, user} <- Users.delete_user(user) do
      {:ok, user}
    else
      {:current_password, false} ->
        {:error, "The password provided is invalid"}
    end
  end

  def delete_account(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete your account"}
  end
end
