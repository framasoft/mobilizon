defmodule Mobilizon.Service.ActivityPub.Activity do
  @moduledoc """
  Represents an activity.
  """

  @type t :: %__MODULE__{
          data: String.t(),
          local: boolean,
          actor: Actor.t(),
          recipients: [String.t()]
          # notifications: [???]
        }

  defstruct [
    :data,
    :local,
    :actor,
    :recipients
    # :notifications
  ]
end
