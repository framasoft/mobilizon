defmodule Eventos.Addresses do
  @moduledoc """
  The Addresses context.
  """

  import Ecto.Query, warn: false
  alias Eventos.Repo

  alias Eventos.Addresses.Address

  import Logger

  @geom_types [:point]

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
  def process_geom(%{"type" => type_input, "data" => data}) do
    type =
      if !is_atom(type_input) && type_input != nil do
        try do
          String.to_existing_atom(type_input)
        rescue
          e in ArgumentError ->
            Logger.error("#{type_input} is not an existing atom : #{inspect(e)}")
            nil
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
      {:error, nil}
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
end
