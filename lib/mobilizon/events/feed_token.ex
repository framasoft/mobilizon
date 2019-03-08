defmodule Mobilizon.Events.FeedToken do
  @moduledoc """
  Represents a Token for a Feed of events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @primary_key false
  schema "feed_tokens" do
    field(:token, Ecto.UUID, primary_key: true)
    belongs_to(:actor, Actor)
    belongs_to(:user, User)

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(%FeedToken{} = feed_token, attrs) do
    feed_token
    |> Ecto.Changeset.cast(attrs, [:token, :actor_id, :user_id])
    |> validate_required([:token, :user_id])
  end
end
