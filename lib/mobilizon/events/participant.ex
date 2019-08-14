import EctoEnum

defenum(Mobilizon.Events.ParticipantRoleEnum, :participant_role_type, [
  :not_approved,
  :participant,
  :moderator,
  :administrator,
  :creator
])

defmodule Mobilizon.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Participant, Event}
  alias Mobilizon.Actors.Actor

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "participants" do
    field(:role, Mobilizon.Events.ParticipantRoleEnum, default: :participant)
    field(:url, :string)
    belongs_to(:event, Event, primary_key: true)
    belongs_to(:actor, Actor, primary_key: true)

    timestamps()
  end

  @doc false
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> Ecto.Changeset.cast(attrs, [:url, :role, :event_id, :actor_id])
    |> generate_url()
    |> validate_required([:url, :role, :event_id, :actor_id])
  end

  # If there's a blank URL that's because we're doing the first insert
  defp generate_url(%Ecto.Changeset{data: %Participant{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} -> changeset
      :error -> do_generate_url(changeset)
    end
  end

  # Most time just go with the given URL
  defp generate_url(%Ecto.Changeset{} = changeset), do: changeset

  defp do_generate_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(
      :url,
      "#{MobilizonWeb.Endpoint.url()}/join/event/#{uuid}"
    )
    |> put_change(
      :id,
      uuid
    )
  end

  @doc """
  We check that the actor asking to leave the event is not it's only organizer
  We start by fetching the list of organizers and if there's only one of them
  and that it's the actor requesting leaving the event we return true
  """
  @spec check_that_participant_is_not_only_organizer(integer(), integer()) :: boolean()
  def check_that_participant_is_not_only_organizer(event_id, actor_id) do
    case Mobilizon.Events.list_organizers_participants_for_event(event_id) do
      [%Participant{actor: %Actor{id: participant_actor_id}}] ->
        participant_actor_id == actor_id

      _ ->
        false
    end
  end
end
