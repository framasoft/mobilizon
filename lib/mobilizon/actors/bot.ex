defmodule Mobilizon.Actors.Bot do
  @moduledoc """
  Represents a local bot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @type t :: %__MODULE__{
          source: String.t(),
          type: String.t(),
          actor: Actor.t(),
          user: User.t()
        }

  @required_attrs [:source]
  @optional_attrs [:type, :actor_id, :user_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "bots" do
    field(:source, :string)
    field(:type, :string, default: "ics")

    belongs_to(:actor, Actor)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = bot, attrs) do
    bot
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
