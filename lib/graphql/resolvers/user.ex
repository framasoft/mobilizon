defmodule Mobilizon.GraphQL.Resolvers.User do
  @moduledoc """
  Handles the user-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Admin, Config, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Crypto
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.{Setting, User}

  alias Mobilizon.Web.{Auth, Email}

  require Logger

  @confirmation_token_length 30

  @doc """
  Find an user by its ID
  """
  def find_user(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_moderator(role) do
    with {:ok, %User{} = user} <- Users.get_user_with_actors(id) do
      {:ok, user}
    end
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
  def list_users(
        _parent,
        %{email: email, page: page, limit: limit, sort: sort, direction: direction},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    {:ok, Users.list_users(email, page, limit, sort, direction)}
  end

  def list_users(_parent, _args, _resolution) do
    {:error, "You need to have admin access to list users"}
  end

  @doc """
  Login an user. Returns a token and the user
  """
  def login_user(_parent, %{email: email, password: password}, _resolution) do
    case Authenticator.authenticate(email, password) do
      {:ok,
       %{access_token: _access_token, refresh_token: _refresh_token, user: _user} =
           user_and_tokens} ->
        {:ok, user_and_tokens}

      {:error, :user_not_found} ->
        {:error, "No user with this email was found"}

      {:error, :disabled_user} ->
        {:error, "This user has been disabled"}

      {:error, _error} ->
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
         {:ok, refresh_token} <- Authenticator.generate_refresh_token(user) do
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
           Authenticator.generate_tokens(user) do
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
         {:can_reset_password, true} <-
           {:can_reset_password, Authenticator.can_reset_password?(user)},
         {:ok, %Bamboo.Email{} = _email_html} <-
           Email.User.send_password_reset_email(user, Map.get(args, :locale, locale)) do
      {:ok, email}
    else
      {:can_reset_password, false} ->
        {:error, "This user can't reset their password"}

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
    with {:ok, %User{email: email} = user} <-
           Email.User.check_reset_password_token(password, token),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Authenticator.authenticate(email, password) do
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
        %{context: %{current_user: %User{id: logged_user_id, role: role}}}
      ) do
    with true <- user_id == logged_user_id or is_moderator(role),
         %Page{} = page <-
           Events.list_participations_for_user(
             user_id,
             Map.get(args, :after_datetime),
             Map.get(args, :before_datetime),
             Map.get(args, :page),
             Map.get(args, :limit)
           ) do
      {:ok, page}
    end
  end

  @doc """
  Returns the list of groups this user is a member is a member of
  """
  def user_memberships(
        %User{id: user_id},
        %{page: page, limit: limit} = _args,
        %{context: %{current_user: %User{id: logged_user_id}}}
      ) do
    with true <- user_id == logged_user_id,
         memberships <-
           Actors.list_memberships_for_user(
             user_id,
             page,
             limit
           ) do
      {:ok, memberships}
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
        %{context: %{current_user: %User{} = user}}
      ) do
    with {:can_change_password, true} <-
           {:can_change_password, Authenticator.can_change_password?(user)},
         {:current_password, {:ok, %User{}}} <-
           {:current_password, Authenticator.login(user.email, old_password)},
         {:same_password, false} <- {:same_password, old_password == new_password},
         {:ok, %User{} = user} <-
           user
           |> User.password_change_changeset(%{"password" => new_password})
           |> Repo.update() do
      {:ok, user}
    else
      {:current_password, _} ->
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
        context: %{current_user: %User{email: old_email} = user}
      }) do
    with {:can_change_password, true} <-
           {:can_change_password, Authenticator.can_change_email?(user)},
         {:current_password, {:ok, %User{}}} <-
           {:current_password, Authenticator.login(user.email, password)},
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
      {:current_password, _} ->
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

  def delete_account(_parent, %{user_id: user_id}, %{
        context: %{current_user: %User{role: role} = moderator_user}
      })
      when is_moderator(role) do
    with {:moderator_actor, %Actor{} = moderator_actor} <-
           {:moderator_actor, Users.get_actor_for_user(moderator_user)},
         %User{disabled: false} = user <- Users.get_user(user_id),
         {:ok, %User{}} <-
           do_delete_account(%User{} = user, Relay.get_actor()) do
      Admin.log_action(moderator_actor, "delete", user)
    else
      {:moderator_actor, nil} ->
        {:error, "No actor found for the moderator user"}

      %User{disabled: true} ->
        {:error, "User already disabled"}
    end
  end

  def delete_account(_parent, args, %{
        context: %{current_user: %User{email: email} = user}
      }) do
    with {:user_has_password, true} <- {:user_has_password, Authenticator.has_password?(user)},
         {:confirmation_password, password} when not is_nil(password) <-
           {:confirmation_password, Map.get(args, :password)},
         {:current_password, {:ok, _}} <-
           {:current_password, Authenticator.authenticate(email, password)} do
      do_delete_account(user)
    else
      # If the user hasn't got any password (3rd-party auth)
      {:user_has_password, false} ->
        do_delete_account(user)

      {:confirmation_password, nil} ->
        {:error, "The password provided is invalid"}

      {:current_password, _} ->
        {:error, "The password provided is invalid"}
    end
  end

  def delete_account(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete your account"}
  end

  defp do_delete_account(%User{} = user, actor_performing \\ nil) do
    with actors <- Users.get_actors_for_user(user),
         activated <- not is_nil(user.confirmed_at),
         # Detach actors from user
         :ok <-
           if(activated,
             do: :ok,
             else: Enum.each(actors, fn actor -> Actors.update_actor(actor, %{user_id: nil}) end)
           ),
         # Launch a background job to delete actors
         :ok <-
           Enum.each(actors, fn actor ->
             actor_performing = actor_performing || actor
             ActivityPub.delete(actor, actor_performing, true)
           end),
         # Delete user
         {:ok, user} <- Users.delete_user(user, reserve_email: activated) do
      {:ok, user}
    end
  end

  @spec user_settings(User.t(), map(), map()) :: {:ok, list(Setting.t())} | {:error, String.t()}
  def user_settings(%User{} = user, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    with {:setting, settings} <- {:setting, Users.get_setting(user)} do
      {:ok, settings}
    end
  end

  def user_settings(%User{id: user_id} = user, _args, %{
        context: %{current_user: %User{id: logged_user_id}}
      }) do
    with {:same_user, true} <- {:same_user, user_id == logged_user_id},
         {:setting, settings} <- {:setting, Users.get_setting(user)} do
      {:ok, settings}
    else
      {:same_user, _} ->
        {:error, "User requested is not logged-in"}
    end
  end

  @spec set_user_setting(map(), map(), map()) :: {:ok, Setting.t()} | {:error, any()}
  def set_user_setting(_parent, attrs, %{
        context: %{current_user: %User{id: logged_user_id}}
      }) do
    attrs = Map.put(attrs, :user_id, logged_user_id)

    res =
      case Users.get_setting(logged_user_id) do
        nil ->
          Users.create_setting(attrs)

        %Setting{} = setting ->
          Users.update_setting(setting, attrs)
      end

    case res do
      {:ok, %Setting{} = setting} ->
        {:ok, setting}

      {:error, changeset} ->
        Logger.debug(inspect(changeset))
        {:error, "Error while saving user setting"}
    end
  end

  def update_locale(_parent, %{locale: locale}, %{
        context: %{current_user: %User{locale: current_locale} = user}
      }) do
    with true <- current_locale != locale,
         {:ok, %User{} = updated_user} <- Users.update_user(user, %{locale: locale}) do
      {:ok, updated_user}
    else
      false ->
        {:ok, user}
    end
  end
end
