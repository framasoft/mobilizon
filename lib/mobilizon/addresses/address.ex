defmodule Mobilizon.Addresses.Address do
  @moduledoc "An address for an event or a group"

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event
  # alias Mobilizon.Actors.Actor
  @attrs [
    :description,
    :floor,
    :geom,
    :country,
    :locality,
    :region,
    :postal_code,
    :street,
    :url,
    :origin_id
  ]
  @required [
    :url
  ]

  schema "addresses" do
    field(:country, :string)
    field(:locality, :string)
    field(:region, :string)
    field(:description, :string)
    field(:floor, :string)
    field(:geom, Geo.PostGIS.Geometry)
    field(:postal_code, :string)
    field(:street, :string)
    field(:url, :string)
    field(:origin_id, :string)
    has_many(:event, Event, foreign_key: :physical_address_id)

    timestamps()
  end

  @doc false
  def changeset(%Address{} = address, attrs) do
    address
    |> cast(attrs, @attrs)
    |> set_url()
    |> validate_required(@required)
  end

  defp set_url(%Ecto.Changeset{changes: changes} = changeset) do
    url =
      Map.get(changes, :url, MobilizonWeb.Endpoint.url() <> "/address/#{Ecto.UUID.generate()}")

    put_change(changeset, :url, url)
  end
end
