defmodule Mobilizon.GraphQL.Schema.StatisticsType do
  @moduledoc """
  Schema representation for Statistics
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Statistics

  @desc "A statistics object"
  object :statistics do
    # Instance name
    field(:number_of_users, :integer, description: "The number of local users")
    field(:number_of_events, :integer, description: "The number of local events")
    field(:number_of_comments, :integer, description: "The number of local comments")
  end

  object :statistics_queries do
    @desc "Get the instance statistics"
    field :statistics, :statistics do
      resolve(&Statistics.get_statistics/3)
    end
  end
end
