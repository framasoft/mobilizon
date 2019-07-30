defmodule Mobilizon.Actors.Follower do
  @moduledoc """
  Represents the following of an actor to another actor
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Follower
  alias Mobilizon.Actors.Actor

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "followers" do
    field(:approved, :boolean, default: false)
    field(:url, :string)
    belongs_to(:target_actor, Actor)
    belongs_to(:actor, Actor)
  end

  @doc false
  def changeset(%Follower{} = member, attrs) do
    member
    |> cast(attrs, [:url, :approved, :target_actor_id, :actor_id])
    |> generate_url()
    |> validate_required([:url, :approved, :target_actor_id, :actor_id])
    |> unique_constraint(:target_actor_id, name: :followers_actor_target_actor_unique_index)
  end

  # If there's a blank URL that's because we're doing the first insert
  defp generate_url(%Ecto.Changeset{data: %Follower{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} -> changeset
      :error -> do_generate_url(changeset)
    end
  end

  # Most time just go with the given URL
  defp generate_url(%Ecto.Changeset{} = changeset), do: changeset

  defp do_generate_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(
      :url,
      "#{MobilizonWeb.Endpoint.url()}/follow/#{uuid}"
    )
    |> put_change(
      :id,
      uuid
    )
  end
end
