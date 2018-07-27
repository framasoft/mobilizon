defmodule EventosWeb.TrackControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Track

  @create_attrs %{color: "some color", description: "some description", name: "some name"}
  @update_attrs %{
    color: "some updated color",
    description: "some updated description",
    name: "some updated name"
  }
  @invalid_attrs %{color: nil, description: nil, name: nil}

  def fixture(:track) do
    {:ok, track} = Events.create_track(@create_attrs)
    track
  end

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    event = insert(:event, organizer_actor: actor)
    {:ok, conn: conn, user: user, event: event}
  end

  describe "index" do
    test "lists all tracks", %{conn: conn} do
      conn = get(conn, track_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create track" do
    test "renders track when data is valid", %{conn: conn, user: user, event: event} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@create_attrs, :event_id, event.id)
      conn = post(conn, track_path(conn, :create), track: attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, track_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "color" => "some color",
               "description" => "some description",
               "name" => "some name"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, user: user, event: event} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :event_id, event.id)
      conn = post(conn, track_path(conn, :create), track: attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update track" do
    setup [:create_track]

    test "renders track when data is valid", %{
      conn: conn,
      track: %Track{id: id} = track,
      user: user,
      event: event
    } do
      conn = auth_conn(conn, user)
      attrs = Map.put(@update_attrs, :event_id, event.id)
      conn = put(conn, track_path(conn, :update, track), track: attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, track_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "color" => "some updated color",
               "description" => "some updated description",
               "name" => "some updated name"
             }
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      track: track,
      user: user,
      event: event
    } do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :event_id, event.id)
      conn = put(conn, track_path(conn, :update, track), track: attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete track" do
    setup [:create_track]

    test "deletes chosen track", %{conn: conn, track: track, user: user} do
      conn = auth_conn(conn, user)
      conn = delete(conn, track_path(conn, :delete, track))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, track_path(conn, :show, track))
      end)
    end
  end

  defp create_track(_) do
    track = insert(:track)
    {:ok, track: track}
  end
end
