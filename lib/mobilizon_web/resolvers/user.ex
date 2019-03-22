defmodule MobilizonWeb.Resolvers.User do
  @moduledoc """
  Handles the user-related GraphQL calls
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.CommonConfig
  alias Mobilizon.Users.User
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Service.Users.{ResetPassword, Activation}
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
        %{
          context: %{current_user: %User{role: role}}
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
         {:ok, token, _} <- Users.authenticate(%{user: user, password: password}) do
      {:ok, %{token: token, user: user}}
    else
      {:error, :user_not_found} ->
        {:error, "User with email not found"}

      {:error, :unauthorized} ->
        {:error, "Impossible to authenticate, either your email or password are invalid."}
    end
  end

  @doc """
  Register an user:
    - check registrations are enabled
    - create the user
    - send a validation email to the user
  """
  @spec create_user(any(), map(), any()) :: tuple()
  def create_user(_parent, args, _resolution) do
    with {:registrations_open, true} <- {:registrations_open, CommonConfig.registrations_open?()},
         {:ok, %User{} = user} <- Users.register(args) do
      Activation.send_confirmation_email(user)
      {:ok, user}
    else
      {:registrations_open, false} ->
        {:error, "Registrations are not enabled"}

      err ->
        err
    end
  end

  @doc """
  Validate an user, get it's actor and a token
  """
  def validate_user(_parent, %{token: token}, _resolution) do
    with {:check_confirmation_token, {:ok, %User{} = user}} <-
           {:check_confirmation_token, Activation.check_confirmation_token(token)},
         {:get_actor, actor} <- {:get_actor, Users.get_actor_for_user(user)},
         {:guardian_encode_and_sign, {:ok, token, _}} <-
           {:guardian_encode_and_sign, MobilizonWeb.Guardian.encode_and_sign(user)} do
      {:ok, %{token: token, user: Map.put(user, :default_actor, actor)}}
    else
      err ->
        Logger.info("Unable to validate user with token #{token}")
        Logger.debug(inspect(err))
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
         {:ok, token, _} <- MobilizonWeb.Guardian.encode_and_sign(user) do
      {:ok, %{token: token, user: user}}
    end
  end

  @doc "Change an user default actor"
  def change_default_actor(_parent, %{preferred_username: username}, %{
        context: %{current_user: user}
      }) do
    with %Actor{id: actor_id} <- Actors.get_local_actor_by_name(username),
         {:user_actor, true} <-
           {:user_actor, actor_id in Enum.map(Users.get_actors_for_user(user), & &1.id)},
         %User{} = user <- Users.update_user_default_actor(user.id, actor_id) do
      {:ok, user}
    else
      {:user_actor, _} ->
        {:error, :actor_not_from_user}

      _err ->
        {:error, :unable_to_change_default_actor}
    end
  end
end
