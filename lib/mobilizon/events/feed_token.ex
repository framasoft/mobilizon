defmodule Mobilizon.Events.FeedToken do
  @moduledoc """
  Represents a token for a feed of events.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @type t :: %__MODULE__{
          token: Ecto.UUID.t(),
          actor: Actor.t(),
          user: User.t()
        }

  @required_attrs [:token, :user_id]
  @optional_attrs [:actor_id]
  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  schema "feed_tokens" do
    field(:token, Ecto.UUID, primary_key: true)

    belongs_to(:actor, Actor)
    belongs_to(:user, User)

    timestamps(updated_at: false)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = feed_token, attrs) do
    feed_token
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
