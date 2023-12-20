defmodule Mobilizon.Instances.InstanceActor do
  @moduledoc """
  An instance actor
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor

  @type t :: %__MODULE__{
          domain: String.t(),
          actor: Actor.t(),
          instance_name: String.t(),
          instance_description: String.t(),
          software: String.t(),
          software_version: String.t()
        }

  schema "instance_actors" do
    field(:domain, :string)
    field(:instance_name, :string)
    field(:instance_description, :string)
    field(:software, :string)
    field(:software_version, :string)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @required_attrs [:domain]
  @optional_attrs [:actor_id, :instance_name, :instance_description, :software, :software_version]
  @attrs @required_attrs ++ @optional_attrs

  def changeset(%__MODULE__{} = instance_actor, attrs) do
    instance_actor
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:domain)
  end
end
