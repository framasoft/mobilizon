defmodule MobilizonWeb.Schema.Actors.FollowerType do
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
  end
end
