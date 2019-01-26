import EctoEnum

defenum(Mobilizon.Events.EventVisibilityEnum, :event_visibility_type, [
  :public,
  :unlisted,
  :private,
  :moderated,
  :invite
])

defenum(Mobilizon.Events.EventStatusEnum, :event_status_type, [
  :tentative,
  :confirmed,
  :cancelled
])

defmodule Mobilizon.Events.Event do
  @moduledoc """
  Represents an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Event, Participant, Tag, Category, Session, Track}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  schema "events" do
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:begins_on, Timex.Ecto.DateTimeWithTimezone)
    field(:description, :string)
    field(:ends_on, Timex.Ecto.DateTimeWithTimezone)
    field(:title, :string)
    field(:status, Mobilizon.Events.EventStatusEnum, default: :confirmed)
    field(:visibility, Mobilizon.Events.EventVisibilityEnum, default: :public)
    field(:thumbnail, :string)
    field(:large_image, :string)
    field(:publish_at, Timex.Ecto.DateTimeWithTimezone)
    field(:uuid, Ecto.UUID, default: Ecto.UUID.generate())
    field(:online_address, :string)
    field(:phone_address, :string)
    belongs_to(:organizer_actor, Actor, foreign_key: :organizer_actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    many_to_many(:tags, Tag, join_through: "events_tags")
    belongs_to(:category, Category)
    many_to_many(:participants, Actor, join_through: Participant)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    belongs_to(:physical_address, Address)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :description,
      :url,
      :begins_on,
      :ends_on,
      :organizer_actor_id,
      :category_id,
      :status,
      :visibility,
      :thumbnail,
      :large_image,
      :publish_at,
      :online_address,
      :phone_address,
      :uuid
    ])
    |> cast_assoc(:tags)
    |> cast_assoc(:physical_address)
    |> validate_required([
      :title,
      :begins_on,
      :organizer_actor_id,
      :category_id,
      :url,
      :uuid
    ])
  end

  def can_event_be_managed_by(%Event{organizer_actor_id: organizer_actor_id}, actor_id)
      when organizer_actor_id == actor_id do
    {:event_can_be_managed, true}
  end

  def can_event_be_managed_by(_event, _actor) do
    {:event_can_be_managed, false}
  end
end
