defmodule Mobilizon.GraphQL.Schema.Events.FeedTokenType do
  @moduledoc """
  Schema representation for Participant.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.GraphQL.Resolvers.FeedToken

  @desc """
  Represents a feed token

  Feed tokens are tokens that are used to provide access to private feeds such as WebCal feed for all of your user's events,
  or an Atom feed for just a profile.
  """
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
    field(:user, :deleted_object, description: "The user that owned the deleted feed token")
    field(:actor, :deleted_object, description: "The actor that owned the deleted feed token")
  end

  object :feed_token_mutations do
    @desc "Create a Feed Token"
    field :create_feed_token, :feed_token do
      arg(:actor_id, :id, description: "The actor ID for the feed token")

      resolve(&FeedToken.create_feed_token/3)
    end

    @desc "Delete a feed token"
    field :delete_feed_token, :deleted_feed_token do
      arg(:token, non_null(:string), description: "The token to delete")

      resolve(&FeedToken.delete_feed_token/3)
    end
  end
end
