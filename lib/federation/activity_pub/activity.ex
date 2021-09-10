defmodule Mobilizon.Federation.ActivityPub.Activity do
  @moduledoc """
  Represents an activity.
  """

  @type t :: %__MODULE__{
          data: map(),
          local: boolean,
          actor: Actor.t(),
          recipients: [String.t()]
        }

  defstruct [
    :data,
    :local,
    :actor,
    :recipients
  ]
end
