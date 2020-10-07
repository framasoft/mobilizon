defmodule Mobilizon.GraphQL.Resolvers.Statistics do
  @moduledoc """
  Handles the statistics-related GraphQL calls.
  """

  alias Mobilizon.Service.Statistics, as: StatisticsModule

  @doc """
  Gets config.
  """
  def get_statistics(_parent, _params, _context) do
    {:ok,
     %{
       number_of_users: StatisticsModule.get_cached_value(:local_users),
       number_of_events: StatisticsModule.get_cached_value(:federation_events),
       number_of_local_events: StatisticsModule.get_cached_value(:local_events),
       number_of_comments: StatisticsModule.get_cached_value(:federation_comments),
       number_of_local_comments: StatisticsModule.get_cached_value(:local_comments),
       number_of_groups: StatisticsModule.get_cached_value(:federation_groups),
       number_of_local_groups: StatisticsModule.get_cached_value(:local_groups),
       number_of_instance_followings: StatisticsModule.get_cached_value(:instance_followings),
       number_of_instance_followers: StatisticsModule.get_cached_value(:instance_followers)
     }}
  end
end
