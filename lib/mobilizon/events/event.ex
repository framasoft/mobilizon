defmodule Mobilizon.Events.Event do
  @moduledoc """
  Represents an event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Addresses, Events, Medias, Mention}
  alias Mobilizon.Addresses.Address

  alias Mobilizon.Discussions.Comment

  alias Mobilizon.Events.{
    EventOptions,
    EventParticipantStats,
    EventStatus,
    EventVisibility,
    JoinOptions,
    Participant,
    Session,
    Tag,
    Track
  }

  alias Mobilizon.Medias.Media
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

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
          picture: Media.t(),
          media: [Media.t()],
          tracks: [Track.t()],
          sessions: [Session.t()],
          mentions: [Mention.t()],
          tags: [Tag.t()],
          participants: [Actor.t()],
          contacts: [Actor.t()]
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
    :local,
    :visibility,
    :join_options,
    :publish_at,
    :online_address,
    :phone_address,
    :picture_id,
    :physical_address_id,
    :attributed_to_id
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
    belongs_to(:physical_address, Address, on_replace: :nilify)
    belongs_to(:picture, Media, on_replace: :update)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    has_many(:mentions, Mention)
    has_many(:comments, Comment)
    many_to_many(:contacts, Actor, join_through: "event_contacts", on_replace: :delete)
    many_to_many(:tags, Tag, join_through: "events_tags", on_replace: :delete)
    many_to_many(:participants, Actor, join_through: Participant)
    many_to_many(:media, Media, join_through: "events_medias", on_replace: :delete)

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
  end

  @doc false
  @spec update_changeset(t, map) :: Changeset.t()
  def update_changeset(%__MODULE__{} = event, attrs) do
    event
    |> cast(attrs, @update_attrs)
    |> common_changeset(attrs)
    |> put_creator_if_published(:update)
    |> validate_required(@update_required_attrs)
  end

  @spec common_changeset(Changeset.t(), map) :: Changeset.t()
  defp common_changeset(%Changeset{} = changeset, attrs) do
    changeset
    |> cast_embed(:options)
    |> put_assoc(:contacts, Map.get(attrs, :contacts, []))
    |> put_assoc(:media, Map.get(attrs, :media, []))
    |> put_tags(attrs)
    |> put_address(attrs)
    |> put_picture(attrs)
    |> validate_lengths()
    |> validate_end_time()
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

  defp validate_end_time(%Changeset{} = changeset) do
    case fetch_field(changeset, :begins_on) do
      {_, begins_on} ->
        validate_change(changeset, :ends_on, fn :ends_on, ends_on ->
          if DateTime.compare(begins_on, ends_on) == :gt,
            do: [ends_on: "ends_on cannot be set before begins_on"],
            else: []
        end)

      :error ->
        changeset
    end
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
  defp put_tags(%Changeset{} = changeset, %{tags: tags}) do
    put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))
  end

  defp put_tags(%Changeset{} = changeset, _), do: changeset

  # We need a changeset instead of a raw struct because of slug which is generated in changeset
  defp process_tag(%{id: id} = _tag) do
    Events.get_tag(id)
  end

  defp process_tag(tag) do
    Tag.changeset(%Tag{}, tag)
  end

  # In case the provided addresses is an existing one
  @spec put_address(Changeset.t(), map) :: Changeset.t()
  defp put_address(%Changeset{} = changeset, %{physical_address: %{id: id} = _physical_address})
       when not is_nil(id) do
    case Addresses.get_address(id) do
      %Address{} = address ->
        put_assoc(changeset, :physical_address, address)

      _ ->
        cast_assoc(changeset, :physical_address)
    end
  end

  # In case it's a new address but the origin_id is an existing one
  defp put_address(%Changeset{} = changeset, %{physical_address: %{origin_id: origin_id}})
       when not is_nil(origin_id) do
    case Repo.get_by(Address, origin_id: origin_id) do
      %Address{} = address ->
        put_assoc(changeset, :physical_address, address)

      _ ->
        cast_assoc(changeset, :physical_address)
    end
  end

  # In case it's a new address without any origin_id (manual)
  defp put_address(%Changeset{} = changeset, _attrs) do
    cast_assoc(changeset, :physical_address)
  end

  # In case the provided picture is an existing one
  @spec put_picture(Changeset.t(), map) :: Changeset.t()
  defp put_picture(%Changeset{} = changeset, %{picture: %{media_id: id} = _picture}) do
    case Medias.get_media!(id) do
      %Media{} = picture ->
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
    put_embed(changeset, :participant_stats, %{creator: 0})
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
