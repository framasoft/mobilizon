defmodule Mobilizon.GraphQL.Schema.FollowedGroupActivityType do
  @moduledoc """
  Schema representation for a follow activity
  """
  use Absinthe.Schema.Notation

  @desc "A paginated list of follow group events"
  object :paginated_followed_group_events do
    field(:elements, list_of(:followed_group_event), description: "A list of follow group events")
    field(:total, :integer, description: "The total number of follow group events in the list")
  end

  @desc "A follow group event"
  object :followed_group_event do
    field(:user, :user)
    field(:profile, :person)
    field(:group, :group)
    field(:event, :event)
  end
end
