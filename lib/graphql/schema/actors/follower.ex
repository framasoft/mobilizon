defmodule Mobilizon.GraphQL.Schema.Actors.FollowerType do
  @moduledoc """
  Schema representation for Follower
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Followers

  @desc """
  Represents an actor's follower
  """
  object :follower do
    field(:id, :id, description: "The follow ID")
    field(:target_actor, :actor, description: "What or who the profile follows")
    field(:actor, :actor, description: "Which profile follows")

    field(:approved, :boolean,
      description: "Whether the follow has been approved by the target actor"
    )

    field(:inserted_at, :datetime, description: "When the follow was created")
    field(:updated_at, :datetime, description: "When the follow was updated")
  end

  @desc """
  A paginated list of follower objects
  """
  object :paginated_follower_list do
    field(:elements, list_of(:follower), description: "A list of followers")
    field(:total, :integer, description: "The total number of elements in the list")
  end

  object :follower_mutations do
    @desc "Update follower"
    field :update_follower, :follower do
      arg(:id, non_null(:id), description: "The follower ID")

      arg(:approved, non_null(:boolean),
        description: "Whether the follower has been approved by the target actor or not"
      )

      resolve(&Followers.update_follower/3)
    end
  end
end
