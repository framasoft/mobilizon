defmodule Mobilizon.Addresses do
  @moduledoc """
  The Addresses context.
  """

  import Ecto.Query, warn: false
  alias Mobilizon.Repo
  require Logger

  alias Mobilizon.Addresses.Address

  @geom_types [:point]

  @doc false
  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc false
  def query(queryable, _params) do
    queryable
  end

  @doc """
  Returns the list of addresses.

  ## Examples

      iex> list_addresses()
      [%Address{}, ...]

  """
  def list_addresses do
    Repo.all(Address)
  end

  @doc """
  Gets a single address.

  Raises `Ecto.NoResultsError` if the Address does not exist.

  ## Examples

      iex> get_address!(123)
      %Address{}

      iex> get_address!(456)
      ** (Ecto.NoResultsError)

  """
  def get_address!(id), do: Repo.get!(Address, id)

  @doc """
  Gets a single address by it's url

  ## Examples

      iex> get_address_by_url("https://mobilizon.social/addresses/4572")
      %Address{}

      iex> get_address_by_url("https://mobilizon.social/addresses/099")
      nil
  """
  def get_address_by_url(url) do
    Repo.get_by(Address, url: url)
  end

  @doc """
  Creates a address.

  ## Examples

      iex> create_address(%{field: value})
      {:ok, %Address{}}

      iex> create_address(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a address.

  ## Examples

      iex> update_address(address, %{field: new_value})
      {:ok, %Address{}}

      iex> update_address(address, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Address.

  ## Examples

      iex> delete_address(address)
      {:ok, %Address{}}

      iex> delete_address(address)
      {:error, %Ecto.Changeset{}}

  """
  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address changes.

  ## Examples

      iex> change_address(address)
      %Ecto.Changeset{source: %Address{}}

  """
  def change_address(%Address{} = address) do
    Address.changeset(address, %{})
  end

  @doc """
  Processes raw geo data informations and return a `Geo` geometry which can be one of `Geo.Point`.
  """
  # TODO: Unused, remove me
  def process_geom(%{"type" => type_input, "data" => data}) do
    type =
      if !is_atom(type_input) && type_input != nil do
        try do
          String.to_existing_atom(type_input)
        rescue
          e in ArgumentError ->
            Logger.error("#{type_input} is not an existing atom : #{inspect(e)}")
            :invalid_type
        end
      else
        type_input
      end

    if Enum.member?(@geom_types, type) do
      case type do
        :point ->
          process_point(data["latitude"], data["longitude"])
      end
    else
      {:error, :invalid_type}
    end
  end

  @doc false
  def process_geom(nil) do
    {:error, nil}
  end

  @spec process_point(number(), number()) :: tuple()
  defp process_point(latitude, longitude) when is_number(latitude) and is_number(longitude) do
    {:ok, %Geo.Point{coordinates: {latitude, longitude}, srid: 4326}}
  end

  defp process_point(_, _) do
    {:error, "Latitude and longitude must be numbers"}
  end

  @doc """
  Search addresses in our database

  We only look at the description for now, and eventually order by object distance
  """
  @spec search_addresses(String.t(), list()) :: list(Address.t())
  def search_addresses(search, options \\ []) do
    limit = Keyword.get(options, :limit, 5)

    query = from(a in Address, where: ilike(a.description, ^"%#{search}%"), limit: ^limit)

    query =
      if coords = Keyword.get(options, :coords, false),
        do:
          from(a in query,
            order_by: [fragment("? <-> ?", a.geom, ^"POINT(#{coords.lon} #{coords.lat})'")]
          ),
        else: query

    query =
      if country = Keyword.get(options, :country, nil),
        do: from(a in query, where: ilike(a.country, ^"%#{country}%")),
        else: query

    if Keyword.get(options, :single, false) == true, do: Repo.one(query), else: Repo.all(query)
  end

  @doc """
  Reverse geocode from coordinates in our database

  We only take addresses 50km around and sort them by distance
  """
  @spec reverse_geocode(number(), number(), list()) :: list(Address.t())
  def reverse_geocode(lon, lat, options) do
    limit = Keyword.get(options, :limit, 5)
    radius = Keyword.get(options, :radius, 50_000)
    country = Keyword.get(options, :country, nil)
    srid = Keyword.get(options, :srid, 4326)

    import Geo.PostGIS

    with {:ok, point} <- Geo.WKT.decode("SRID=#{srid};POINT(#{lon} #{lat})") do
      query =
        from(a in Address,
          order_by: [fragment("? <-> ?", a.geom, ^point)],
          limit: ^limit,
          where: st_dwithin_in_meters(^point, a.geom, ^radius)
        )

      query =
        if country,
          do: from(a in query, where: ilike(a.country, ^"%#{country}%")),
          else: query

      Repo.all(query)
    end
  end
end
