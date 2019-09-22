defmodule Mobilizon.Events.Event do
  @moduledoc """
  Represents an event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  alias Mobilizon.Events.{
    EventOptions,
    EventStatus,
    EventVisibility,
    JoinOptions,
    Participant,
    Tag,
    Session,
    Track
  }

  alias Mobilizon.Media.Picture

  @type t :: %__MODULE__{
          url: String.t(),
          local: boolean,
          begins_on: DateTime.t(),
          slug: String.t(),
          description: String.t(),
          ends_on: DateTime.t(),
          title: String.t(),
          status: EventStatus.t(),
          visibility: EventVisibility.t(),
          join_options: JoinOptions.t(),
          publish_at: DateTime.t(),
          uuid: Ecto.UUID.t(),
          online_address: String.t(),
          phone_address: String.t(),
          category: String.t(),
          options: EventOptions.t(),
          organizer_actor: Actor.t(),
          attributed_to: Actor.t(),
          physical_address: Address.t(),
          picture: Picture.t(),
          tracks: [Track.t()],
          sessions: [Session.t()],
          tags: [Tag.t()],
          participants: [Actor.t()]
        }

  @required_attrs [:title, :begins_on, :organizer_actor_id, :url, :uuid]
  @optional_attrs [
    :slug,
    :description,
    :ends_on,
    :category,
    :status,
    :visibility,
    :publish_at,
    :online_address,
    :phone_address,
    :picture_id,
    :physical_address_id
  ]
  @attrs @required_attrs ++ @optional_attrs

  @update_required_attrs @required_attrs

  @update_optional_attrs [
    :slug,
    :description,
    :ends_on,
    :category,
    :status,
    :visibility,
    :join_options,
    :publish_at,
    :online_address,
    :phone_address,
    :picture_id,
    :physical_address_id
  ]
  @update_attrs @update_required_attrs ++ @update_optional_attrs

  schema "events" do
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:begins_on, :utc_datetime)
    field(:slug, :string)
    field(:description, :string)
    field(:ends_on, :utc_datetime)
    field(:title, :string)
    field(:status, EventStatus, default: :confirmed)
    field(:visibility, EventVisibility, default: :public)
    field(:join_options, JoinOptions, default: :free)
    field(:publish_at, :utc_datetime)
    field(:uuid, Ecto.UUID, default: Ecto.UUID.generate())
    field(:online_address, :string)
    field(:phone_address, :string)
    field(:category, :string)

    embeds_one(:options, EventOptions, on_replace: :update)
    belongs_to(:organizer_actor, Actor, foreign_key: :organizer_actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:physical_address, Address)
    belongs_to(:picture, Picture)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    many_to_many(:tags, Tag, join_through: "events_tags", on_replace: :delete)
    many_to_many(:participants, Actor, join_through: Participant)

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event, attrs) do
    event
    |> cast(attrs, @attrs)
    |> cast_embed(:options)
    |> validate_required(@required_attrs)
  end

  @doc false
  @spec update_changeset(t, map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = event, attrs) do
    event
    |> Ecto.Changeset.cast(attrs, @update_attrs)
    |> cast_embed(:options)
    |> put_tags(attrs)
    |> validate_required(@update_required_attrs)
  end

  @doc """
  Checks whether an event can be managed.
  """
  @spec can_be_managed_by(t, integer | String.t()) :: boolean
  def can_be_managed_by(%__MODULE__{organizer_actor_id: organizer_actor_id}, actor_id)
      when organizer_actor_id == actor_id do
    {:event_can_be_managed, true}
  end

  def can_be_managed_by(_event, _actor), do: {:event_can_be_managed, false}

  @spec put_tags(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_tags(changeset, %{"tags" => tags}), do: put_assoc(changeset, :tags, tags)
  defp put_tags(changeset, _), do: changeset
end
