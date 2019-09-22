defmodule Mobilizon.Events.EventParticipationCondition do
  @moduledoc """
  Represents an event participation condition.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          title: String.t(),
          content: String.t(),
          url: String.t()
        }

  embedded_schema do
    field(:title, :string)
    field(:content, :string)
    field(:url, :string)
  end
end
