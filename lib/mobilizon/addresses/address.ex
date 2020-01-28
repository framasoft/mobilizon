defmodule Mobilizon.Addresses.Address do
  @moduledoc """
  Represents an address for an event or a group.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.Event

  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          country: String.t(),
          locality: String.t(),
          region: String.t(),
          description: String.t(),
          geom: Geo.PostGIS.Geometry.t(),
          postal_code: String.t(),
          street: String.t(),
          type: String.t(),
          url: String.t(),
          origin_id: String.t(),
          events: [Event.t()]
        }

  @required_attrs [:url]
  @optional_attrs [
    :description,
    :geom,
    :country,
    :locality,
    :region,
    :postal_code,
    :street,
    :origin_id,
    :type
  ]
  @attrs @required_attrs ++ @optional_attrs

  schema "addresses" do
    field(:country, :string)
    field(:locality, :string)
    field(:region, :string)
    field(:description, :string)
    field(:geom, Geo.PostGIS.Geometry)
    field(:postal_code, :string)
    field(:street, :string)
    field(:type, :string)
    field(:url, :string)
    field(:origin_id, :string)

    has_many(:events, Event, foreign_key: :physical_address_id)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = address, attrs) do
    address
    |> cast(attrs, @attrs)
    |> set_url()
    |> validate_required(@required_attrs)
  end

  @spec set_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_url(%Ecto.Changeset{changes: changes} = changeset) do
    url = Map.get(changes, :url, "#{Endpoint.url()}/address/#{Ecto.UUID.generate()}")

    put_change(changeset, :url, url)
  end

  def coords(nil), do: nil

  def coords(%__MODULE__{} = address) do
    with %Geo.Point{coordinates: {latitude, longitude}, srid: 4326} <- address.geom do
      {latitude, longitude}
    end
  end

  def representation(nil), do: nil

  def representation(%__MODULE__{} = address) do
    "#{address.street} #{address.postal_code} #{address.locality} #{address.region} #{
      address.country
    }"
  end
end
