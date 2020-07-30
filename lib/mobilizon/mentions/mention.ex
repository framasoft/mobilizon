defmodule Mobilizon.Mention do
  @moduledoc """
  The Mentions context.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo

  @type t :: %__MODULE__{
          silent: boolean,
          actor: Actor.t(),
          event: Event.t(),
          comment: Comment.t()
        }

  @required_attrs [:actor_id]
  @optional_attrs [:silent, :event_id, :comment_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "mentions" do
    field(:silent, :boolean, default: false)
    belongs_to(:actor, Actor)
    belongs_to(:event, Event)
    belongs_to(:comment, Comment)

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, @attrs)
    # TODO: Enforce having either event_id or comment_id
    |> validate_required(@required_attrs)
  end

  @doc """
  Creates a new mention
  """
  @spec create_mention(map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def create_mention(args) do
    with {:ok, %__MODULE__{} = mention} <-
           %__MODULE__{}
           |> changeset(args)
           |> Repo.insert() do
      {:ok, Repo.preload(mention, [:actor, :event, :comment])}
    end
  end
end
