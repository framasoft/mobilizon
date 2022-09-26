defmodule Mobilizon.Service.GlobalSearch.EventResult do
  @moduledoc """
  The structure holding search result information about an event
  """
  defstruct [
    :id,
    :uuid,
    :url,
    :title,
    :begins_on,
    :ends_on,
    :picture,
    :category,
    :tags,
    :organizer_actor,
    :participant_stats,
    :physical_address
  ]
end
