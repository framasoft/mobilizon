defmodule Mobilizon.Addresses.Address do
  @moduledoc "An address for an event or a group"

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event
  # alias Mobilizon.Actors.Actor

  schema "addresses" do
    field(:country, :string)
    field(:locality, :string)
    field(:region, :string)
    field(:description, :string)
    field(:floor, :string)
    field(:geom, Geo.PostGIS.Geometry)
    field(:postal_code, :string)
    field(:street, :string)
    has_one(:event, Event, foreign_key: :physical_address_id)
    # has_one(:group, Actor)

    timestamps()
  end

  @doc false
  def changeset(%Address{} = address, attrs) do
    address
    |> cast(attrs, [
      :description,
      :floor,
      :geom,
      :country,
      :locality,
      :region,
      :postal_code,
      :street
    ])
  end
end
