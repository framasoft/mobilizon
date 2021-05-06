defmodule Mobilizon.GraphQL.Resolvers.PushSubscription do
  @moduledoc """
  Handles the push subscriptions-related GraphQL calls.
  """

  alias Mobilizon.Users
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.{PushSubscription, User}

  @doc """
  List all of an user's registered push subscriptions
  """
  def list_user_push_subscriptions(_parent, %{page: page, limit: limit}, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    %Page{} = page = Users.list_user_push_subscriptions(user_id, page, limit)
    {:ok, page}
  end

  def list_user_push_subscriptions(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Register a push subscription
  """
  def register_push_subscription(_parent, args, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    Users.create_push_subscription(Map.put(args, :user_id, user_id))
  end

  @spec unregister_push_subscription(map(), map(), map()) ::
          {:ok, PushSubscription.t()} | {:error, :unauthorized} | {:error, :not_found}
  def unregister_push_subscription(_parent, %{id: push_subscription_id}, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    with %PushSubscription{user: %User{id: push_subscription_user_id}} = push_subscription <-
           Users.get_push_subscription(push_subscription_id),
         {:user_owns_push_subscription, true} <-
           {:user_owns_push_subscription, push_subscription_user_id == user_id} do
      Users.delete_push_subscription(push_subscription)
    else
      {:user_owns_push_subscription, false} ->
        {:error, :unauthorized}

      nil ->
        {:error, :not_found}
    end
  end
end
