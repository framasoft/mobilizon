defmodule Mobilizon.Actors.Bot do
  @moduledoc """
  Represents a local bot
  """
  use Mobilizon.Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.{Actor, User}

  schema "bots" do
    field(:source, :string)
    field(:type, :string, default: :ics)
    belongs_to(:actor, Actor)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(bot, attrs) do
    bot
    |> cast(attrs, [:source, :type, :actor_id, :user_id])
    |> validate_required([:source])
  end
end
