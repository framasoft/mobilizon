defmodule Mobilizon.Conversations.ConversationParticipant do
  @moduledoc """
  Represents a conversation participant
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation

  @type t :: %__MODULE__{
          conversation: Conversation.t(),
          actor: Actor.t(),
          unread: boolean()
        }

  @required_attrs [:actor_id, :conversation_id]
  @optional_attrs [:unread]
  @attrs @required_attrs ++ @optional_attrs

  schema "conversation_participants" do
    belongs_to(:conversation, Conversation)
    belongs_to(:actor, Actor)
    field(:unread, :boolean, default: true)

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = conversation, attrs) do
    conversation
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:actor_id)
  end
end
