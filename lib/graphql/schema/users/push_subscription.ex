defmodule Mobilizon.GraphQL.Schema.Users.PushSubscription do
  @moduledoc """
  Schema representation for PushSubscription
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.PushSubscription

  # object :push_subscription do
  #   field(:id, :id)
  # end

  # @desc "A paginated list of subscriptions"
  # object :paginated_push_subscription_list do
  #   field(:elements, list_of(:push_subscription), description: "A list of push subscriptions")
  #   field(:total, :integer, description: "The total number of push subscriptions in the list")
  # end

  # object :push_queries do
  #   field :list_push_subscriptions, :paginated_push_subscription_list do
  #     resolve(&PushSubscription.list_user_push_subscriptions/3)
  #   end
  # end

  object :push_mutations do
    field :register_push, :string do
      arg(:endpoint, non_null(:string))
      arg(:auth, non_null(:string))
      arg(:p256dh, non_null(:string))
      resolve(&PushSubscription.register_push_subscription/3)
    end

    field :unregister_push, :string do
      arg(:endpoint, non_null(:string))
      resolve(&PushSubscription.unregister_push_subscription/3)
    end
  end
end
