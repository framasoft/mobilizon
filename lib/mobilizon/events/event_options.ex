import EctoEnum

defenum(Mobilizon.Events.CommentModeration, :comment_moderation, [:allow_all, :moderated, :closed])

defmodule Mobilizon.Events.EventOffer do
  @moduledoc """
  Represents an event offer
  """
  use Ecto.Schema

  embedded_schema do
    field(:price, :float)
    field(:price_currency, :string)
    field(:url, :string)
  end
end

defmodule Mobilizon.Events.EventParticipationCondition do
  @moduledoc """
  Represents an event participation condition
  """
  use Ecto.Schema

  embedded_schema do
    field(:title, :string)
    field(:content, :string)
    field(:url, :string)
  end
end

defmodule Mobilizon.Events.EventOptions do
  @moduledoc """
  Represents an event options
  """
  use Ecto.Schema

  alias Mobilizon.Events.{
    EventOptions,
    EventOffer,
    EventParticipationCondition,
    CommentModeration
  }

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:maximum_attendee_capacity, :integer)
    field(:remaining_attendee_capacity, :integer)
    field(:show_remaining_attendee_capacity, :boolean)
    embeds_many(:offers, EventOffer)
    embeds_many(:participation_condition, EventParticipationCondition)
    field(:attendees, {:array, :string})
    field(:program, :string)
    field(:comment_moderation, CommentModeration)
    field(:show_participation_price, :boolean)
  end

  def changeset(%EventOptions{} = event_options, attrs) do
    event_options
    |> Ecto.Changeset.cast(attrs, [
      :maximum_attendee_capacity,
      :remaining_attendee_capacity,
      :show_remaining_attendee_capacity,
      :attendees,
      :program,
      :comment_moderation,
      :show_participation_price
    ])
  end
end
