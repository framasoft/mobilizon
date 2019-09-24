defmodule MobilizonWeb.Resolvers.User do
  @moduledoc """
  Handles the user-related GraphQL calls
  """

  alias Mobilizon.{Actors, Config, Users, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Users.{ResetPassword, Activation}
  alias Mobilizon.Users.User
  alias Mobilizon.Storage.Repo

  import Mobilizon.Users.Guards

  require Logger

  @doc """
  Find an user by it's ID
  """
  def find_user(_parent, %{id: id}, _resolution) do
    Users.get_user_with_actors(id)
  end

  @doc """
  Return current logged-in user
  """
  def get_current_user(
        _parent,
        _args,
        %{
          context: %{
            current_user: user
          }
        }
      ) do
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
        %{
          context: %{
            current_user: %User{
              role: role
            }
          }
        }
      )
      when is_moderator(role) do
    total = Task.async(&Users.count_users/0)
    elements = Task.async(fn -> Users.list_users(page, limit, sort, direction) end)

    {:ok, %{total: Task.await(total), elements: Task.await(elements)}}
  end

  def list_and_count_users(_parent, _args, _resolution),
    do: {:error, "You need to have admin access to list users"}

  @doc """
  Login an user. Returns a token and the user
  """
  def login_user(_parent, %{email: email, password: password}, _resolution) do
    with {:ok, %User{} = user} <- Users.get_user_by_email(email, true),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Users.authenticate(%{user: user, password: password}) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}}
    else
      {:error, :user_not_found} ->
        {:error, "User with email not found"}

      {:error, :unauthorized} ->
        {:error, "Impossible to authenticate, either your email or password are invalid."}
    end
  end

  @doc """
  Refresh a token
  """
  def refresh_token(
        _parent,
        %{
          refresh_token: refresh_token
        },
        _context
      ) do
    with {:ok, user, _claims} <- MobilizonWeb.Guardian.resource_from_token(refresh_token),
         {:ok, _old, {exchanged_token, _claims}} <-
           MobilizonWeb.Guardian.exchange(refresh_token, ["access", "refresh"], "access"),
         {:ok, refresh_token} <- Users.generate_refresh_token(user) do
      {:ok, %{access_token: exchanged_token, refresh_token: refresh_token}}
    else
      {:error, message} ->
        Logger.debug("Cannot refresh user token: #{inspect(message)}")
        {:error, "Cannot refresh the token"}
    end
  end

  def refresh_token(_parent, _params, _context),
    do: {:error, "You need to have an existing token to get a refresh token"}

  @doc """
  Register an user:
    - check registrations are enabled
    - create the user
    - send a validation email to the user
  """
  @spec create_user(any(), map(), any()) :: tuple()
  def create_user(_parent, args, _resolution) do
    with {:registrations_open, true} <-
           {:registrations_open, Config.instance_registrations_open?()},
         {:ok, %User{} = user} <- Users.register(args) do
      Activation.send_confirmation_email(user)
      {:ok, user}
    else
      {:registrations_open, false} ->
        {:error, "Registrations are not enabled"}

      error ->
        error
    end
  end

  @doc """
  Validate an user, get it's actor and a token
  """
  def validate_user(_parent, %{token: token}, _resolution) do
    with {:check_confirmation_token, {:ok, %User{} = user}} <-
           {:check_confirmation_token, Activation.check_confirmation_token(token)},
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
  def resend_confirmation_email(_parent, %{email: email, locale: locale}, _resolution) do
    with {:ok, user} <- Users.get_user_by_email(email, false),
         {:ok, email} <-
           Activation.resend_confirmation_email(user, locale) do
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
  def send_reset_password(_parent, %{email: email, locale: locale}, _resolution) do
    with {:ok, user} <- Users.get_user_by_email(email, true),
         {:ok, %Bamboo.Email{} = _email_html} <-
           ResetPassword.send_password_reset_email(user, locale) do
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
           ResetPassword.check_reset_password_token(password, token),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Users.authenticate(%{user: user, password: password}) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}}
    end
  end

  @doc "Change an user default actor"
  def change_default_actor(
        _parent,
        %{preferred_username: username},
        %{
          context: %{
            current_user: user
          }
        }
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
  def user_participations(_parent, args, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    with participations <-
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

  def change_password(_parent, %{old_password: old_password, new_password: new_password}, %{
        context: %{current_user: %User{password_hash: old_password_hash} = user}
      }) do
    with {:current_password, true} <-
           {:current_password, Argon2.verify_pass(old_password, old_password_hash)},
         {:same_password, false} <- {:same_password, old_password == new_password},
         {:ok, %User{} = user} <-
           user
           |> User.password_change_changeset(%{
             "password" => new_password
           })
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
end
