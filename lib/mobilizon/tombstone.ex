defmodule Mobilizon.Tombstone do
  @moduledoc """
  Represent tombstones for deleted objects. Saves only URI
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.Repo
  require Ecto.Query

  @type t :: %__MODULE__{
          uri: String.t(),
          actor: Actor.t()
        }

  @required_attrs [:uri, :actor_id]
  @optional_attrs []
  @attrs @required_attrs ++ @optional_attrs

  schema "tombstones" do
    field(:uri, :string)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = tombstone, attrs) do
    tombstone
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end

  @spec create_tombstone(map) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_tombstone(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :uri)
  end

  @spec find_tombstone(String.t()) :: Ecto.Schema.t() | nil
  def find_tombstone(uri) do
    __MODULE__
    |> Ecto.Query.where([t], t.uri == ^uri)
    |> Ecto.Query.preload([t], [:actor])
    |> Repo.one()
  end

  @spec delete_actor_tombstones(String.t() | integer()) :: {integer(), nil}
  def delete_actor_tombstones(actorId) do
    __MODULE__
    |> Ecto.Query.where(actor_id: ^actorId)
    |> Repo.delete_all()
  end

  def delete_uri_tombstone(uri) do
    __MODULE__
    |> Ecto.Query.where(uri: ^uri)
    |> Repo.delete_all()
  end
end
