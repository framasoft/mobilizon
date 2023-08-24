defmodule Mobilizon.GraphQL.Resolvers.PushSubscription do
  @moduledoc """
  Handles the push subscriptions-related GraphQL calls.
  """

  alias Mobilizon.Storage.Page
  alias Mobilizon.Users
  alias Mobilizon.Users.{PushSubscription, User}
  import Mobilizon.Web.Gettext

  @doc """
  List all of an user's registered push subscriptions
  """
  @spec list_user_push_subscriptions(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(PushSubscription.t())} | {:error, :unauthenticated}
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
  @spec register_push_subscription(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def register_push_subscription(_parent, args, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    case Users.create_push_subscription(Map.put(args, :user_id, user_id)) do
      {:ok, %PushSubscription{}} ->
        {:ok, "OK"}

      {:error,
       %Ecto.Changeset{
         errors: [
           digest:
             {"has already been taken",
              [
                constraint: :unique,
                constraint_name: "user_push_subscriptions_user_id_digest_index"
              ]}
         ]
       }} ->
        {:error, dgettext("errors", "The same push subscription has already been registered")}

      {:error, err} ->
        require Logger
        Logger.error(inspect(err))
        {:error, "Something went wrong"}
    end
  end

  @spec unregister_push_subscription(map(), map(), map()) ::
          {:ok, PushSubscription.t()} | {:error, :unauthorized} | {:error, :not_found}
  def unregister_push_subscription(_parent, %{endpoint: push_subscription_endpoint}, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    with %PushSubscription{user: %User{id: push_subscription_user_id}} = push_subscription <-
           Users.get_push_subscription_by_endpoint(push_subscription_endpoint),
         {:user_owns_push_subscription, true} <-
           {:user_owns_push_subscription, push_subscription_user_id == user_id},
         {:ok, %PushSubscription{}} <- Users.delete_push_subscription(push_subscription) do
      {:ok, "OK"}
    else
      {:user_owns_push_subscription, false} ->
        {:error, :unauthorized}

      nil ->
        {:error, :not_found}

      {:error, err} ->
        require Logger
        Logger.error(inspect(err))
        {:error, "Something went wrong"}
    end
  end
end
