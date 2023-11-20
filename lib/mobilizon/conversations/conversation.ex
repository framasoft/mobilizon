defmodule Mobilizon.Conversations.Conversation do
  @moduledoc """
  Represents a conversation
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.ConversationParticipant
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event

  @type t :: %__MODULE__{
          id: String.t(),
          origin_comment: Comment.t(),
          last_comment: Comment.t(),
          participants: list(Actor.t())
        }

  @required_attrs [:origin_comment_id, :last_comment_id]
  @optional_attrs [:event_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "conversations" do
    belongs_to(:origin_comment, Comment)
    belongs_to(:last_comment, Comment)
    belongs_to(:event, Event)
    has_many(:comments, Comment)

    many_to_many(:participants, Actor,
      join_through: ConversationParticipant,
      join_keys: [conversation_id: :id, actor_id: :id],
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = conversation, attrs) do
    conversation
    |> cast(attrs, @attrs)
    |> maybe_set_participants(attrs)
    |> validate_required(@required_attrs)
  end

  defp maybe_set_participants(%Changeset{} = changeset, %{participants: participants})
       when length(participants) > 0 do
    put_assoc(changeset, :participants, participants)
  end

  defp maybe_set_participants(%Changeset{} = changeset, _), do: changeset
end
