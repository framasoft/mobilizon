defmodule EventosWeb.EventControllerTest do
  use EventosWeb.ConnCase
  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Event
  alias Eventos.Export.ICalendar

  @create_attrs %{begins_on: "2010-04-17 14:00:00.000000Z", description: "some description", ends_on: "2010-04-17 14:00:00.000000Z", title: "some title"}
  @update_attrs %{begins_on: "2011-05-18 15:01:01.000000Z", description: "some updated description", ends_on: "2011-05-18 15:01:01.000000Z", title: "some updated title"}
  @invalid_attrs %{begins_on: nil, description: nil, ends_on: nil, title: nil, address_id: nil}
  @create_address_attrs %{"addressCountry" => "some addressCountry", "addressLocality" => "some addressLocality", "addressRegion" => "some addressRegion", "description" => "some description", "floor" => "some floor", "postalCode" => "some postalCode", "streetAddress" => "some streetAddress", "geom" => %{"type" => :point, "data" => %{"latitude" => -20, "longitude" => 30}}}

  def fixture(:event) do
    {:ok, event} = Events.create_event(@create_attrs)
    event
  end

  def address_fixture do
    insert(:address)
  end

  setup %{conn: conn} do
    actor = insert(:actor)
    user = insert(:user, actor: actor)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all events", %{conn: conn} do
      conn = get conn, event_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{conn: conn, user: user} do
      attrs = Map.put(@create_attrs, :organizer_actor_id, user.actor.id)
      attrs = Map.put(attrs, "physical_address", @create_address_attrs)

      category = insert(:category)
      attrs = Map.put(attrs, :category_id, category.id)
      conn = auth_conn(conn, user)
      conn = post conn, event_path(conn, :create), event: attrs
      assert %{"uuid" => uuid} = json_response(conn, 201)["data"]

      conn = get conn, event_path(conn, :show, uuid)
      assert %{
        "begins_on" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "ends_on" => "2010-04-17T14:00:00Z",
        "title" => "some title",
        "participants" => [],
        "physical_address" => %{"addressCountry" => "some addressCountry", "addressLocality" => "some addressLocality", "addressRegion" => "some addressRegion", "floor" => "some floor", "geom" => %{"data" => %{"latitude" => -20.0, "longitude" => 30.0}, "type" => "point"}, "postalCode" => "some postalCode", "streetAddress" => "some streetAddress"}
       } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :organizer_actor_id, user.actor.id)
      attrs = Map.put(attrs, :address, @create_address_attrs)
      conn = post conn, event_path(conn, :create), event: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "export event" do
    setup [:create_event]

    test "renders ics export of event", %{conn: conn, event: %Event{uuid: uuid} = event, user: user} do
      conn = auth_conn(conn, user)
      conn = get conn, event_path(conn, :export_to_ics, uuid)
      exported_event = ICalendar.export_event(event)
      assert exported_event == response(conn, 200)
    end
  end

  describe "update event" do
    setup [:create_event]

    test "renders event when data is valid", %{conn: conn, event: %Event{uuid: uuid} = event, user: user} do
      conn = auth_conn(conn, user)
      address = address_fixture()
      attrs = Map.put(@update_attrs, :organizer_actor_id, user.actor.id)
      attrs = Map.put(attrs, :address_id, address.id)
      conn = put conn, event_path(conn, :update, uuid), event: attrs
      assert %{"uuid" => uuid} = json_response(conn, 200)["data"]

      conn = get conn, event_path(conn, :show, uuid)
      assert %{
               "begins_on" => "2011-05-18T15:01:01Z",
               "description" => "some updated description",
               "ends_on" => "2011-05-18T15:01:01Z",
               "title" => "some updated title",
               "participants" => [],
               "physical_address" => %{"addressCountry" => "My Country", "addressLocality" => "My Locality", "addressRegion" => "My Region", "floor" => "Myfloor", "geom" => %{"data" => %{"latitude" => 30.0, "longitude" => -90.0}, "type" => "point"}, "postalCode" => "My Postal Code", "streetAddress" => "My Street Address"}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, event: %Event{uuid: uuid} = event, user: user} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :organizer_actor_id, user.actor.id)
      conn = put conn, event_path(conn, :update, uuid), event: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    test "deletes chosen event", %{conn: conn, event: %Event{uuid: uuid} = event, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, event_path(conn, :delete, uuid)
      assert response(conn, 204)
      conn = get conn, event_path(conn, :show, uuid)
      assert response(conn, 404)
    end
  end

  defp create_event(_) do
    actor = insert(:actor)
    event = insert(:event, organizer_actor: actor)
    {:ok, event: event, actor: actor}
  end
end
