defmodule Mobilizon.Admin.ActionLog do
  @moduledoc """
  Represents an action log entity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Admin.ActionLogAction

  @type t :: %__MODULE__{
          action: String.t(),
          target_type: String.t(),
          target_id: integer,
          changes: map,
          actor: Actor.t()
        }

  @required_attrs [:action, :target_type, :target_id, :changes, :actor_id]
  @attrs @required_attrs

  @timestamps_opts [type: :utc_datetime]

  schema "admin_action_logs" do
    field(:action, ActionLogAction)
    field(:target_type, :string)
    field(:target_id, :integer)
    field(:changes, :map)

    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = action_log, attrs) do
    action_log
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
