defmodule Mobilizon.Actors.Follower do
  @moduledoc """
  Represents the following of an actor to another actor.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor

  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          approved: boolean,
          url: String.t(),
          target_actor: Actor.t(),
          actor: Actor.t()
        }

  @required_attrs [:url, :approved, :target_actor_id, :actor_id]
  @attrs @required_attrs

  @timestamps_opts [type: :utc_datetime]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "followers" do
    field(:approved, :boolean, default: false)
    field(:url, :string)

    timestamps()

    belongs_to(:target_actor, Actor)
    belongs_to(:actor, Actor)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(follower, attrs) do
    follower
    |> cast(attrs, @attrs)
    |> ensure_url()
    |> validate_required(@required_attrs)
    |> unique_constraint(:target_actor_id,
      name: :followers_actor_target_actor_unique_index
    )
  end

  # If there's a blank URL that's because we're doing the first insert
  @spec ensure_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp ensure_url(%Ecto.Changeset{data: %__MODULE__{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        generate_url(changeset)
    end
  end

  # Most time just go with the given URL
  defp ensure_url(%Ecto.Changeset{} = changeset), do: changeset

  @spec generate_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp generate_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(:id, uuid)
    |> put_change(:url, "#{Endpoint.url()}/follow/#{uuid}")
  end
end
