defmodule Mobilizon.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant, ParticipantRole}

  @type t :: %__MODULE__{
          role: ParticipantRole.t(),
          url: String.t(),
          event: Event.t(),
          actor: Actor.t()
        }

  @required_attrs [:url, :role, :event_id, :actor_id]
  @attrs @required_attrs

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "participants" do
    field(:role, ParticipantRole, default: :participant)
    field(:url, :string)

    belongs_to(:event, Event, primary_key: true)
    belongs_to(:actor, Actor, primary_key: true)

    timestamps()
  end

  @doc """
  We check that the actor asking to leave the event is not it's only organizer.
  We start by fetching the list of organizers and if there's only one of them
  and that it's the actor requesting leaving the event we return true.
  """
  @spec is_not_only_organizer(integer | String.t(), integer | String.t()) :: boolean
  def is_not_only_organizer(event_id, actor_id) do
    case Events.list_organizers_participants_for_event(event_id) do
      [%Participant{actor: %Actor{id: participant_actor_id}}] ->
        participant_actor_id == actor_id

      _ ->
        false
    end
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> cast(attrs, @attrs)
    |> ensure_url()
    |> validate_required(@required_attrs)
  end

  # If there's a blank URL that's because we're doing the first insert
  @spec ensure_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp ensure_url(%Ecto.Changeset{data: %Participant{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        update_url(changeset)
    end
  end

  defp ensure_url(%Ecto.Changeset{} = changeset), do: changeset

  defp update_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()
    url = generate_url(uuid)

    changeset
    |> put_change(:id, uuid)
    |> put_change(:url, url)
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(uuid), do: "#{Config.instance_hostname()}/join/event/#{uuid}"
end
