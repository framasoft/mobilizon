defmodule Mobilizon.GraphQL.Schema.Users.PushSubscription do
  @moduledoc """
  Schema representation for PushSubscription
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.PushSubscription

  @desc """
  An object representing the keys for a push subscription
  """
  input_object :push_subscription_keys do
    field(:p256dh, non_null(:string))
    field(:auth, non_null(:string))
  end

  object :push_queries do
    field :list_push_subscriptions, :paginated_push_subscription_list do
      resolve(&PushSubscription.list_user_push_subscriptions/3)
    end
  end

  object :push_mutations do
    field :register_push_mutation, :string do
      arg(:endpoint, non_null(:string))
      arg(:keys, non_null(:push_subscription_keys))
      resolve(&PushSubscription.register_push_subscription/3)
    end

    field :unregister_push_mutation, :string do
      arg(:id, non_null(:id))
      resolve(&PushSubscription.unregister_push_subscription/3)
    end
  end
end
