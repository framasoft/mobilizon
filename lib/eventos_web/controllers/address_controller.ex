defmodule EventosWeb.AddressController do
  @moduledoc """
  A controller for addresses
  """

  use EventosWeb, :controller

  alias Eventos.Addresses
  alias Eventos.Addresses.Address

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    addresses = Addresses.list_addresses()
    render(conn, "index.json", addresses: addresses)
  end

  def create(conn, %{"address" => address_params}) do
    address_params = %{address_params | "geom" => process_geom(address_params["geom"])}
    with {:ok, %Address{} = address} <- Addresses.create_address(address_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", address_path(conn, :show, address))
      |> render("show.json", address: address)
    end
  end

  def process_geom(%{"type" => type, "data" => data}) do
    types = [:point]
    unless is_atom(type) do
      type = String.to_existing_atom(type)
    end
    case type do
      :point ->
        %Geo.Point{coordinates: {data["latitude"], data["longitude"]}, srid: 4326}
      nil ->
        nil
    end
  end

  def process_geom(nil) do
    nil
  end

  def show(conn, %{"id" => id}) do
    address = Addresses.get_address!(id)
    render(conn, "show.json", address: address)
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    address = Addresses.get_address!(id)
    address_params = %{address_params | "geom" => process_geom(address_params["geom"])}

    with {:ok, %Address{} = address} <- Addresses.update_address(address, address_params) do
      render(conn, "show.json", address: address)
    end
  end

  def delete(conn, %{"id" => id}) do
    address = Addresses.get_address!(id)
    with {:ok, %Address{}} <- Addresses.delete_address(address) do
      send_resp(conn, :no_content, "")
    end
  end
end
