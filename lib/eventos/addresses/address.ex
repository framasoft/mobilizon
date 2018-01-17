defmodule Eventos.Addresses.Address do
  @moduledoc "An address for an event or a group"

  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Addresses.Address
  alias Eventos.Events.Event
  alias Eventos.Groups.Group

  schema "addresses" do
    field :addressCountry, :string
    field :addressLocality, :string
    field :addressRegion, :string
    field :description, :string
    field :floor, :string
    field :geom, Geo.Geometry
    field :postalCode, :string
    field :streetAddress, :string
    has_one :event, Event
    has_one :group, Group

    timestamps()
  end

  @doc false
  def changeset(%Address{} = address, attrs) do
    address
    |> cast(attrs, [:description, :floor, :geom, :addressCountry, :addressLocality, :addressRegion, :postalCode, :streetAddress])
    |> validate_required([:geom])
  end
end
