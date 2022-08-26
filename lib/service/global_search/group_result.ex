defmodule Mobilizon.Service.GlobalSearch.GroupResult do
  @moduledoc """
  The structure holding search result information about a group
  """
  defstruct [
    :id,
    :url,
    :name,
    :preferred_username,
    :domain,
    :avatar,
    :summary,
    :url,
    :members_count,
    :follower_count,
    :type,
    :physical_address
  ]
end
