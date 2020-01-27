defmodule Mobilizon.GraphQL.Schema.Events.FeedTokenType do
  @moduledoc """
  Schema representation for Participant.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.GraphQL.Resolvers.FeedToken

  @desc "Represents a participant to an event"
  object :feed_token do
    field(
      :actor,
      :actor,
      resolve: dataloader(Actors),
      description: "The event which the actor participates in"
    )

    field(
      :user,
      :user,
      resolve: dataloader(Users),
      description: "The actor that participates to the event"
    )

    field(:token, :string, description: "The role of this actor at this event")
  end

  @desc "Represents a deleted feed_token"
  object :deleted_feed_token do
    field(:user, :deleted_object)
    field(:actor, :deleted_object)
  end

  object :feed_token_mutations do
    @desc "Create a Feed Token"
    field :create_feed_token, :feed_token do
      arg(:actor_id, :id)

      resolve(&FeedToken.create_feed_token/3)
    end

    @desc "Delete a feed token"
    field :delete_feed_token, :deleted_feed_token do
      arg(:token, non_null(:string))

      resolve(&FeedToken.delete_feed_token/3)
    end
  end
end
