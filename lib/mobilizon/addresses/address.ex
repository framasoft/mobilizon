defmodule Mobilizon.Addresses.Address do
  @moduledoc """
  Represents an address for an event or a group.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.Event

  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          country: String.t() | nil,
          locality: String.t() | nil,
          region: String.t() | nil,
          description: String.t() | nil,
          geom: Geo.PostGIS.Geometry.t() | nil,
          postal_code: String.t() | nil,
          street: String.t() | nil,
          type: String.t() | nil,
          url: String.t(),
          origin_id: String.t() | nil,
          events: [Event.t()],
          timezone: String.t() | nil
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
    :type,
    :timezone
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
    field(:timezone, :string)

    has_many(:events, Event, foreign_key: :physical_address_id)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = address, attrs) do
    address
    |> cast(attrs, @attrs)
    |> maybe_set_timezone()
    |> set_url()
    |> validate_required(@required_attrs)
    |> unique_constraint(:url, name: :addresses_url_index)
  end

  @spec set_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_url(%Ecto.Changeset{changes: changes} = changeset) do
    url = Map.get(changes, :url, "#{Endpoint.url()}/address/#{Ecto.UUID.generate()}")

    put_change(changeset, :url, url)
  end

  @spec coords(nil | t) :: nil | {float, float}
  def coords(nil), do: nil

  def coords(%__MODULE__{} = address) do
    with %Geo.Point{coordinates: {longitude, latitude}, srid: 4326} <- address.geom do
      {latitude, longitude}
    end
  end

  @spec representation(nil | t) :: nil | String.t()
  def representation(nil), do: nil

  def representation(%__MODULE__{} = address) do
    String.trim(
      "#{address.street} #{address.postal_code} #{address.locality} #{address.region} #{address.country}"
    )
  end

  @spec maybe_set_timezone(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_set_timezone(%Ecto.Changeset{} = changeset) do
    case get_change(changeset, :geom) do
      nil ->
        changeset

      geom ->
        case get_field(changeset, :timezone) do
          # Only update the timezone if the geom has change and we don't already have a set timezone
          nil -> put_change(changeset, :timezone, timezone(geom))
          _ -> changeset
        end
    end
  end

  @spec timezone(Geo.PostGIS.Geometry.t() | nil) :: String.t() | nil
  defp timezone(nil), do: nil

  defp timezone(geom) do
    case TzWorld.timezone_at(geom) do
      {:ok, tz} -> tz
      {:error, _err} -> nil
    end
  end
end
