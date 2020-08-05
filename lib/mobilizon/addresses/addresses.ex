defmodule Mobilizon.Addresses do
  @moduledoc """
  The Addresses context.
  """

  import Ecto.Query

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Storage.Repo

  require Logger

  @doc """
  Gets a single address.
  """
  @spec get_address(integer | String.t()) :: Address.t() | nil
  def get_address(id), do: Repo.get(Address, id)

  @doc """
  Gets a single address.
  Raises `Ecto.NoResultsError` if the address does not exist.
  """
  @spec get_address!(integer | String.t()) :: Address.t()
  def get_address!(id), do: Repo.get!(Address, id)

  @doc """
  Gets a single address by its url.
  """
  @spec get_address_by_url(String.t()) :: Address.t() | nil
  def get_address_by_url(url), do: Repo.get_by(Address, url: url)

  @spec get_address_by_origin_id(String.t()) :: Address.t() | nil
  def get_address_by_origin_id(origin_id), do: Repo.get_by(Address, origin_id: origin_id)

  @doc """
  Creates an address.
  """
  @spec create_address(map) :: {:ok, Address.t()} | {:error, Ecto.Changeset.t()}
  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: [:origin_id]
    )
  end

  @doc """
  Updates an address.
  """
  @spec update_address(Address.t(), map) :: {:ok, Address.t()} | {:error, Ecto.Changeset.t()}
  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an address.
  """
  @spec delete_address(Address.t()) :: {:ok, Address.t()} | {:error, Ecto.Changeset.t()}
  def delete_address(%Address{} = address), do: Repo.delete(address)

  @doc """
  Returns the list of addresses.
  """
  @spec list_addresses :: [Address.t()]
  def list_addresses, do: Repo.all(Address)

  @doc """
  Searches addresses.

  We only look at the description for now, and eventually order by object distance.
  """
  @spec search_addresses(String.t(), keyword) :: [Address.t()]
  def search_addresses(search, options \\ []) do
    query =
      search
      |> search_addresses_query(Keyword.get(options, :limit, 5))
      |> order_by_coords(Keyword.get(options, :coords))
      |> filter_by_contry(Keyword.get(options, :country))

    case Keyword.get(options, :single, false) do
      true ->
        Repo.one(query)

      false ->
        Repo.all(query)
    end
  end

  @doc """
  Reverse geocode from coordinates.

  We only take addresses 50km around and sort them by distance.
  """
  @spec reverse_geocode(number, number, keyword) :: [Address.t()]
  def reverse_geocode(lon, lat, options) do
    limit = Keyword.get(options, :limit, 5)
    radius = Keyword.get(options, :radius, 50_000)
    country = Keyword.get(options, :country)
    srid = Keyword.get(options, :srid, 4326)

    with {:ok, point} <- Geo.WKT.decode("SRID=#{srid};POINT(#{lon} #{lat})") do
      point
      |> addresses_around_query(radius, limit)
      |> filter_by_contry(country)
      |> Repo.all()
    end
  end

  @spec search_addresses_query(String.t(), integer) :: Ecto.Query.t()
  defp search_addresses_query(search, limit) do
    from(
      a in Address,
      where: ilike(a.description, ^"%#{search}%"),
      limit: ^limit
    )
  end

  @spec order_by_coords(Ecto.Query.t(), map | nil) :: Ecto.Query.t()
  defp order_by_coords(query, nil), do: query

  defp order_by_coords(query, coords) do
    from(
      a in query,
      order_by: [fragment("? <-> ?", a.geom, ^"POINT(#{coords.lon} #{coords.lat})'")]
    )
  end

  @spec filter_by_contry(Ecto.Query.t(), String.t() | nil) :: Ecto.Query.t()
  defp filter_by_contry(query, nil), do: query

  defp filter_by_contry(query, country) do
    from(
      a in query,
      where: ilike(a.country, ^"%#{country}%")
    )
  end

  @spec addresses_around_query(Geo.geometry(), integer, integer) :: Ecto.Query.t()
  defp addresses_around_query(point, radius, limit) do
    import Geo.PostGIS

    from(a in Address,
      where: st_dwithin_in_meters(^point, a.geom, ^radius),
      order_by: [fragment("? <-> ?", a.geom, ^point)],
      limit: ^limit
    )
  end
end
