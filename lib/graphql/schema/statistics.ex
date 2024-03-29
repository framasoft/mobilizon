defmodule Mobilizon.GraphQL.Schema.StatisticsType do
  @moduledoc """
  Schema representation for Statistics
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Statistics

  @desc "A statistics object"
  object :statistics do
    meta(:authorize, :all)
    # Instance name
    field(:number_of_users, :integer, description: "The number of local users")
    field(:number_of_events, :integer, description: "The total number of events")
    field(:number_of_local_events, :integer, description: "The number of local events")
    field(:number_of_comments, :integer, description: "The total number of comments")
    field(:number_of_local_comments, :integer, description: "The number of local events")
    field(:number_of_groups, :integer, description: "The total number of groups")
    field(:number_of_local_groups, :integer, description: "The number of local groups")

    field(:number_of_instance_followers, :integer,
      description: "The number of this instance's followers"
    )

    field(:number_of_instance_followings, :integer,
      description: "The number of instances this instance follows"
    )
  end

  object :category_statistics do
    meta(:authorize, :all)
    field(:key, :string, description: "The key for the category")
    field(:number, :integer, description: "The number of events for the given category")
  end

  object :statistics_queries do
    @desc "Get the instance statistics"
    field :statistics, :statistics do
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Statistics.get_statistics/3)
    end

    @desc "Get the instance's category statistics"
    field :category_statistics, list_of(:category_statistics) do
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Statistics.get_category_statistics/3)
    end
  end
end
