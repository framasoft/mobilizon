defmodule Mobilizon.Conversations.Conversation.TitleSlug do
  @moduledoc """
  Module to generate the slug for conversations
  """
  use EctoAutoslugField.Slug, from: :title, to: :slug
end

defmodule Mobilizon.Conversations.Conversation do
  @moduledoc """
  Represents a conversation
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Conversations.Conversation.TitleSlug

  @type t :: %__MODULE__{
          creator: Actor.t(),
          actor: Actor.t(),
          title: String.t(),
          slug: String.t(),
          last_comment: Comment.t(),
          comments: list(Comment.t())
        }

  @required_attrs [:actor_id, :creator_id, :title, :last_comment_id]
  @optional_attrs []
  @attrs @required_attrs ++ @optional_attrs

  schema "conversations" do
    field(:title, :string)
    field(:slug, TitleSlug.Type)
    belongs_to(:creator, Actor)
    belongs_to(:actor, Actor)
    belongs_to(:last_comment, Comment)
    has_many(:comments, Comment, foreign_key: :conversation_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = conversation, attrs) do
    conversation
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> TitleSlug.maybe_generate_slug()
  end
end
