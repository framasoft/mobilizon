defmodule Mobilizon.Events.EventParticipantStats do
  @moduledoc """
  Participation stats on event
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          not_approved: integer(),
          rejected: integer(),
          participant: integer(),
          moderator: integer(),
          administrator: integer(),
          creator: integer()
        }

  @attrs [
    :not_approved,
    :rejected,
    :participant,
    :moderator,
    :administrator,
    :moderator,
    :creator
  ]

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:not_approved, :integer, default: 0)
    field(:rejected, :integer, default: 0)
    field(:participant, :integer, default: 0)
    field(:moderator, :integer, default: 0)
    field(:administrator, :integer, default: 0)
    field(:creator, :integer, default: 0)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event_options, attrs) do
    cast(event_options, attrs, @attrs)
  end
end
