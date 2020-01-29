defmodule Mobilizon.Share do
  @moduledoc """
  Holds the list of shares made to external actors
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.Repo

  @type t :: %__MODULE__{
          uri: String.t(),
          actor: Actor.t()
        }

  @required_attrs [:uri, :actor_id, :owner_actor_id]
  @optional_attrs []
  @attrs @required_attrs ++ @optional_attrs

  schema "shares" do
    field(:uri, :string)

    belongs_to(:actor, Actor)
    belongs_to(:owner_actor, Actor)
    timestamps()
  end

  @doc false
  def changeset(share, attrs) do
    share
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:actor_id)
    |> unique_constraint(:uri, name: :shares_uri_actor_id_index)
  end

  @spec create(String.t(), integer(), integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(uri, actor_id, owner_actor_id) do
    %__MODULE__{}
    |> changeset(%{actor_id: actor_id, owner_actor_id: owner_actor_id, uri: uri})
    |> Repo.insert(on_conflict: :nothing)
  end

  @spec get(String.t(), integer()) :: Ecto.Schema.t() | nil
  def get(uri, actor_id) do
    __MODULE__
    |> where(actor_id: ^actor_id, uri: ^uri)
    |> Repo.one()
  end

  @spec get_actors_by_share_uri(String.t()) :: [Ecto.Schema.t()]
  def get_actors_by_share_uri(uri) do
    Actor
    |> join(:inner, [a], s in __MODULE__, on: s.actor_id == a.id)
    |> where([_a, s], s.uri == ^uri)
    |> Repo.all()
  end

  @spec get_actors_by_owner_actor_id(integer()) :: [Ecto.Schema.t()]
  def get_actors_by_owner_actor_id(actor_id) do
    Actor
    |> join(:inner, [a], s in __MODULE__, on: s.actor_id == a.id)
    |> where([_a, s], s.owner_actor_id == ^actor_id)
    |> Repo.all()
  end

  @spec delete_all_by_uri(String.t()) :: {integer(), nil | [term()]}
  def delete_all_by_uri(uri) do
    __MODULE__
    |> where(uri: ^uri)
    |> Repo.delete_all()
  end
end
