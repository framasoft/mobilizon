defmodule Mobilizon.Events.Event do
  @moduledoc """
  Represents an event.
  """

  use Ecto.Schema

  import Ecto.Changeset
  alias Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  alias Mobilizon.Addresses

  alias Mobilizon.Events.{
    EventOptions,
    EventStatus,
    EventVisibility,
    JoinOptions,
    EventParticipantStats,
    Participant,
    Session,
    Tag,
    Track
  }

  alias Mobilizon.Media
  alias Mobilizon.Media.Picture
  alias Mobilizon.Mention

  alias MobilizonWeb.Endpoint
  alias MobilizonWeb.Router.Helpers, as: Routes

  @type t :: %__MODULE__{
          url: String.t(),
          local: boolean,
          begins_on: DateTime.t(),
          slug: String.t(),
          description: String.t(),
          ends_on: DateTime.t(),
          title: String.t(),
          status: EventStatus.t(),
          draft: boolean,
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
          mentions: [Mention.t()],
          tags: [Tag.t()],
          participants: [Actor.t()]
        }

  @update_required_attrs [:title, :begins_on, :organizer_actor_id]
  @required_attrs @update_required_attrs ++ [:url, :uuid]

  @optional_attrs [
    :slug,
    :description,
    :ends_on,
    :category,
    :status,
    :draft,
    :visibility,
    :join_options,
    :publish_at,
    :online_address,
    :phone_address,
    :picture_id,
    :physical_address_id
  ]
  @attrs @required_attrs ++ @optional_attrs

  @update_attrs @update_required_attrs ++ @optional_attrs

  schema "events" do
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:begins_on, :utc_datetime)
    field(:slug, :string)
    field(:description, :string)
    field(:ends_on, :utc_datetime)
    field(:title, :string)
    field(:status, EventStatus, default: :confirmed)
    field(:draft, :boolean, default: false)
    field(:visibility, EventVisibility, default: :public)
    field(:join_options, JoinOptions, default: :free)
    field(:publish_at, :utc_datetime)
    field(:uuid, Ecto.UUID, default: Ecto.UUID.generate())
    field(:online_address, :string)
    field(:phone_address, :string)
    field(:category, :string)

    embeds_one(:options, EventOptions, on_replace: :delete)
    embeds_one(:participant_stats, EventParticipantStats, on_replace: :update)
    belongs_to(:organizer_actor, Actor, foreign_key: :organizer_actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:physical_address, Address, on_replace: :update)
    belongs_to(:picture, Picture, on_replace: :update)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    has_many(:mentions, Mention)
    many_to_many(:tags, Tag, join_through: "events_tags", on_replace: :delete)
    many_to_many(:participants, Actor, join_through: Participant)

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = event, attrs) do
    attrs = Map.update(attrs, :uuid, Ecto.UUID.generate(), & &1)
    attrs = Map.update(attrs, :url, Routes.page_url(Endpoint, :event, attrs.uuid), & &1)

    event
    |> cast(attrs, @attrs)
    |> common_changeset(attrs)
    |> put_creator_if_published(:create)
    |> validate_required(@required_attrs)
    |> validate_lengths()
  end

  @doc false
  @spec update_changeset(t, map) :: Changeset.t()
  def update_changeset(%__MODULE__{} = event, attrs) do
    event
    |> cast(attrs, @update_attrs)
    |> common_changeset(attrs)
    |> put_creator_if_published(:update)
    |> validate_required(@update_required_attrs)
    |> validate_lengths()
  end

  @spec common_changeset(Changeset.t(), map) :: Changeset.t()
  defp common_changeset(%Changeset{} = changeset, attrs) do
    changeset
    |> cast_embed(:options)
    |> put_tags(attrs)
    |> put_address(attrs)
    |> put_picture(attrs)
  end

  @spec validate_lengths(Changeset.t()) :: Changeset.t()
  defp validate_lengths(%Changeset{} = changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:online_address, min: 3, max: 2000)
    |> validate_length(:phone_address, min: 3, max: 200)
    |> validate_length(:category, min: 2, max: 100)
    # |> validate_length(:category, min: 2, max: 100)
    |> validate_length(:slug, min: 3, max: 200)
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

  @spec put_tags(Changeset.t(), map) :: Changeset.t()
  defp put_tags(%Changeset{} = changeset, %{tags: tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(%Changeset{} = changeset, _), do: changeset

  # We need a changeset instead of a raw struct because of slug which is generated in changeset
  defp process_tag(%{id: _id} = tag), do: tag

  defp process_tag(tag) do
    Tag.changeset(%Tag{}, tag)
  end

  # In case the provided addresses is an existing one
  @spec put_address(Changeset.t(), map) :: Changeset.t()
  defp put_address(%Changeset{} = changeset, %{physical_address: %{id: id} = _physical_address}) when not is_nil(id) do
    case Addresses.get_address(id) do
      %Address{} = address ->
        put_assoc(changeset, :physical_address, address)

      _ ->
        changeset
    end
  end

  # In case it's a new address
  defp put_address(%Changeset{} = changeset, _attrs) do
    cast_assoc(changeset, :physical_address)
  end

  # In case the provided picture is an existing one
  @spec put_picture(Changeset.t(), map) :: Changeset.t()
  defp put_picture(%Changeset{} = changeset, %{picture: %{picture_id: id} = _picture}) do
    case Media.get_picture!(id) do
      %Picture{} = picture ->
        put_assoc(changeset, :picture, picture)

      _ ->
        changeset
    end
  end

  # In case it's a new picture
  defp put_picture(%Changeset{} = changeset, _attrs) do
    cast_assoc(changeset, :picture)
  end

  # Created or updated with draft parameter: don't publish
  defp put_creator_if_published(
         %Changeset{changes: %{draft: true}} = changeset,
         _action
       ) do
    cast_embed(changeset, :participant_stats)
  end

  # Created with any other value: publish
  defp put_creator_if_published(
         %Changeset{} = changeset,
         :create
       ) do
    changeset
    |> put_embed(:participant_stats, %{creator: 1})
  end

  # Updated from draft false to true: publish
  defp put_creator_if_published(
         %Changeset{
           data: %{draft: false},
           changes: %{draft: true}
         } = changeset,
         :update
       ) do
    changeset
    |> put_embed(:participant_stats, %{creator: 1})
  end

  defp put_creator_if_published(%Changeset{} = changeset, _),
    do: cast_embed(changeset, :participant_stats)
end
