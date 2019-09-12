defmodule Mobilizon.Events.EventOptions do
  @moduledoc """
  Represents an event options.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.{
    EventOffer,
    EventParticipationCondition,
    CommentModeration
  }

  @type t :: %__MODULE__{
          maximum_attendee_capacity: integer,
          remaining_attendee_capacity: integer,
          show_remaining_attendee_capacity: boolean,
          attendees: [String.t()],
          program: String.t(),
          comment_moderation: CommentModeration.t(),
          show_participation_price: boolean,
          offers: [EventOffer.t()],
          participation_condition: [EventParticipationCondition.t()]
        }

  @attrs [
    :maximum_attendee_capacity,
    :remaining_attendee_capacity,
    :show_remaining_attendee_capacity,
    :attendees,
    :program,
    :comment_moderation,
    :show_participation_price
  ]

  @primary_key false
  embedded_schema do
    field(:maximum_attendee_capacity, :integer)
    field(:remaining_attendee_capacity, :integer)
    field(:show_remaining_attendee_capacity, :boolean)
    field(:attendees, {:array, :string})
    field(:program, :string)
    field(:comment_moderation, CommentModeration)
    field(:show_participation_price, :boolean)

    embeds_many(:offers, EventOffer)
    embeds_many(:participation_condition, EventParticipationCondition)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event_options, attrs) do
    cast(event_options, attrs, @attrs)
  end
end
