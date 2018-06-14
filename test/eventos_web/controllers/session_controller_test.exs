defmodule EventosWeb.SessionControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Session

  @create_attrs %{audios_urls: "some audios_urls", language: "some language", long_abstract: "some long_abstract", short_abstract: "some short_abstract", slides_url: "some slides_url", subtitle: "some subtitle", title: "some title", videos_urls: "some videos_urls"}
  @update_attrs %{audios_urls: "some updated audios_urls", language: "some updated language", long_abstract: "some updated long_abstract", short_abstract: "some updated short_abstract", slides_url: "some updated slides_url", subtitle: "some updated subtitle", title: "some updated title", videos_urls: "some updated videos_urls"}
  @invalid_attrs %{audios_urls: nil, language: nil, long_abstract: nil, short_abstract: nil, slides_url: nil, subtitle: nil, title: nil, videos_urls: nil}

  def fixture(:session) do
    {:ok, session} = Events.create_session(@create_attrs)
    session
  end

  setup %{conn: conn} do
    actor = insert(:actor)
    user = insert(:user, actor: actor)
    event = insert(:event, organizer_actor: actor)
    {:ok, conn: conn, user: user, event: event}
  end

  describe "index" do
    test "lists all sessions", %{conn: conn} do
      conn = get conn, session_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create session" do
    test "renders session when data is valid", %{conn: conn, user: user, event: event} do
      conn = auth_conn(conn, user)
      event_id = event.id
      attrs = Map.put(@create_attrs, :event_id, event_id)
      conn = post conn, session_path(conn, :create), session: attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, session_path(conn, :show_sessions_for_event, event.uuid)
      assert hd(json_response(conn, 200)["data"])["id"] == id

      conn = get conn, session_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "audios_urls" => "some audios_urls",
        "language" => "some language",
        "long_abstract" => "some long_abstract",
        "short_abstract" => "some short_abstract",
        "slides_url" => "some slides_url",
        "subtitle" => "some subtitle",
        "title" => "some title",
        "videos_urls" => "some videos_urls"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user, event: event} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :event_id, event.id)
      conn = post conn, session_path(conn, :create), session: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update session" do
    setup [:create_session]

    test "renders session when data is valid", %{conn: conn, session: %Session{id: id} = session, user: user, event: event} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@update_attrs, :event_id, event.id)
      conn = patch conn, session_path(conn, :update, session), session: attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, session_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "audios_urls" => "some updated audios_urls",
        "language" => "some updated language",
        "long_abstract" => "some updated long_abstract",
        "short_abstract" => "some updated short_abstract",
        "slides_url" => "some updated slides_url",
        "subtitle" => "some updated subtitle",
        "title" => "some updated title",
        "videos_urls" => "some updated videos_urls"}
    end

    test "renders errors when data is invalid", %{conn: conn, session: session, user: user} do
      conn = auth_conn(conn, user)
      conn = patch conn, session_path(conn, :update, session), session: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete session" do
    setup [:create_session]

    test "deletes chosen session", %{conn: conn, session: session, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, session_path(conn, :delete, session)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, session_path(conn, :show, session)
      end
    end
  end

  defp create_session(_) do
    session = insert(:session)
    {:ok, session: session}
  end
end
