defmodule Mobilizon.Admin.ActionLog do
  @moduledoc """
  ActionLog entity schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor

  @required_attrs [:action, :target_type, :target_id, :changes, :actor_id]

  schema "admin_action_logs" do
    field(:action, :string)
    field(:target_type, :string)
    field(:target_id, :integer)
    field(:changes, :map)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  def changeset(action_log, attrs) do
    action_log
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs -- [:changes])
  end
end
