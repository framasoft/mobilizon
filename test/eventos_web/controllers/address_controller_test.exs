defmodule EventosWeb.AddressControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Addresses
  alias Eventos.Addresses.Address

  @create_attrs %{addressCountry: "some addressCountry", addressLocality: "some addressLocality", addressRegion: "some addressRegion", description: "some description", floor: "some floor", postalCode: "some postalCode", streetAddress: "some streetAddress", geom: %{type: :point, data: %{latitude: -20, longitude: 30}}}
  @update_attrs %{addressCountry: "some updated addressCountry", addressLocality: "some updated addressLocality", addressRegion: "some updated addressRegion", description: "some updated description", floor: "some updated floor", postalCode: "some updated postalCode", streetAddress: "some updated streetAddress", geom: %{type: :point, data: %{latitude: -40, longitude: 40}}}
  @invalid_attrs %{addressCountry: nil, addressLocality: nil, addressRegion: nil, description: nil, floor: nil, postalCode: nil, streetAddress: nil, geom: %{type: nil, data: %{latitude: nil, longitude: nil}}}

  def fixture(:address) do
    {:ok, address} = Addresses.create_address(@create_attrs)
    address
  end

  setup %{conn: conn} do
    actor = insert(:actor)
    user = insert(:user, actor: actor)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all addresses", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = get conn, address_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create address" do
    test "renders address when data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, address_path(conn, :create), address: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, address_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "addressCountry" => "some addressCountry",
        "addressLocality" => "some addressLocality",
        "addressRegion" => "some addressRegion",
        "description" => "some description",
        "floor" => "some floor",
        "postalCode" => "some postalCode",
        "streetAddress" => "some streetAddress",
        "geom" => %{"data" => %{"latitude" => -20.0, "longitude" => 30.0}, "type" => "point"}
       }
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = post conn, address_path(conn, :create), address: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update address" do
    setup [:create_address]

    test "renders address when data is valid", %{conn: conn, address: %Address{id: id} = address, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, address_path(conn, :update, address), address: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, address_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "addressCountry" => "some updated addressCountry",
        "addressLocality" => "some updated addressLocality",
        "addressRegion" => "some updated addressRegion",
        "description" => "some updated description",
        "floor" => "some updated floor",
        "postalCode" => "some updated postalCode",
        "streetAddress" => "some updated streetAddress",
        "geom" => %{"data" => %{"latitude" => -40.0, "longitude" => 40.0}, "type" => "point"}
       }
    end

    test "renders errors when data is invalid", %{conn: conn, address: address, user: user} do
      conn = auth_conn(conn, user)
      conn = put conn, address_path(conn, :update, address), address: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete address" do
    setup [:create_address]

    test "deletes chosen address", %{conn: conn, address: address, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, address_path(conn, :delete, address)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, address_path(conn, :show, address)
      end
    end
  end

  defp create_address(_) do
    {:ok, address: insert(:address)}
  end
end
