defmodule Mobilizon.Admin.ActionLog do
  @moduledoc """
  Represents an action log entity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor

  @type t :: %__MODULE__{
          action: String.t(),
          target_type: String.t(),
          target_id: integer,
          changes: map,
          actor: Actor.t()
        }

  @required_attrs [:action, :target_type, :target_id, :actor_id]
  @optional_attrs [:changes]
  @attrs @required_attrs ++ @optional_attrs

  schema "admin_action_logs" do
    field(:action, :string)
    field(:target_type, :string)
    field(:target_id, :integer)
    field(:changes, :map)

    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(action_log, attrs) do
    action_log
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
