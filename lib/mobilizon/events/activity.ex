defmodule Mobilizon.Events.Activity do
  @moduledoc """
  Represents an activity.
  """

  defstruct [
    :data,
    :local,
    :actor,
    :recipients,
    :notifications
  ]
end
