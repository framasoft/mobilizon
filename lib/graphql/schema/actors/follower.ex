defmodule Mobilizon.GraphQL.Schema.Actors.FollowerType do
  @moduledoc """
  Schema representation for Follower
  """
  use Absinthe.Schema.Notation

  @desc """
  Represents an actor's follower
  """
  object :follower do
    field(:target_actor, :actor, description: "What or who the profile follows")
    field(:actor, :actor, description: "Which profile follows")

    field(:approved, :boolean,
      description: "Whether the follow has been approved by the target actor"
    )

    field(:inserted_at, :datetime, description: "When the follow was created")
    field(:updated_at, :datetime, description: "When the follow was updated")
  end

  object :paginated_follower_list do
    field(:elements, list_of(:follower), description: "A list of followers")
    field(:total, :integer, description: "The total number of elements in the list")
  end
end
