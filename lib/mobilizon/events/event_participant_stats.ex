defmodule Mobilizon.Events.EventParticipantStats do
  @moduledoc """
  Participation stats on event
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          not_approved: integer(),
          not_confirmed: integer(),
          rejected: integer(),
          participant: integer(),
          moderator: integer(),
          administrator: integer(),
          creator: integer()
        }

  @attrs [
    :not_approved,
    :not_confirmed,
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
    field(:not_confirmed, :integer, default: 0)
    field(:rejected, :integer, default: 0)
    field(:participant, :integer, default: 0)
    field(:moderator, :integer, default: 0)
    field(:administrator, :integer, default: 0)
    field(:creator, :integer, default: 0)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event_options, attrs) do
    event_options
    |> cast(attrs, @attrs)
    |> validate_stats()
  end

  defp validate_stats(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_number(:not_approved, greater_than_or_equal_to: 0)
    |> validate_number(:not_confirmed, greater_than_or_equal_to: 0)
    |> validate_number(:rejected, greater_than_or_equal_to: 0)
    |> validate_number(:participant, greater_than_or_equal_to: 0)
    |> validate_number(:moderator, greater_than_or_equal_to: 0)
    |> validate_number(:administrator, greater_than_or_equal_to: 0)
    |> validate_number(:creator, greater_than_or_equal_to: 0)

    # TODO: Replace me with something like the following
    # Enum.reduce(@attrs, fn key, changeset -> validate_number(changeset, key, greater_than_or_equal_to: 0) end)
  end
end
