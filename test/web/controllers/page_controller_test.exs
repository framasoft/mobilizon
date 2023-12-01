defmodule Mobilizon.Web.PageControllerTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActorSuspension
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  setup do
    conn = build_conn() |> put_req_header("accept", "text/html")
    {:ok, conn: conn}
  end

  describe "GET /" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200)
    end
  end

  describe "GET /@actor" do
    test "GET /@actor with existing group", %{conn: conn} do
      actor = insert(:group)
      conn = get(conn, Actor.build_url(actor.preferred_username, :page))
      assert html_response(conn, 200) =~ actor.preferred_username
    end

    test "GET /@actor with existing person", %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      conn = get(conn, Actor.build_url(actor.preferred_username, :page))
      assert html_response(conn, 404)
    end

    test "GET /@actor with not existing group", %{conn: conn} do
      conn = get(conn, Actor.build_url("not_existing", :page))
      assert html_response(conn, 404)
    end

    test "GET /@actor when suspended", %{conn: conn} do
      suspended = insert(:actor)

      conn = get(conn, Actor.build_url(suspended.preferred_username, :page))
      assert html_response(conn, 200)

      ActorSuspension.suspend_actor(suspended)

      conn = get(conn, Actor.build_url(suspended.preferred_username, :page))
      assert html_response(conn, 404)
    end
  end

  test "GET /events/:uuid", %{conn: conn} do
    event = insert(:event, visibility: :public)
    conn = get(conn, url(~p"/events/#{event.uuid}"))
    assert html_response(conn, 200) =~ event.title
  end

  test "GET /events/:uuid with unlisted event", %{conn: conn} do
    event = insert(:event, visibility: :unlisted)
    conn = get(conn, url(~p"/events/#{event.uuid}"))
    assert html_response(conn, 200) =~ event.title
    assert ["noindex"] == get_resp_header(conn, "x-robots-tag")
  end

  test "GET /events/:uuid with not existing event", %{conn: conn} do
    conn = get(conn, ~p"/events/not_existing_event")
    assert html_response(conn, 404)
  end

  test "GET /events/:uuid with event not public", %{conn: conn} do
    event = insert(:event, visibility: :restricted)
    conn = get(conn, url(~p"/events/#{event.uuid}"))
    assert html_response(conn, 404)
  end

  test "GET /comments/:uuid", %{conn: conn} do
    comment = insert(:comment)
    conn = get(conn, url(~p"/comments/#{comment.uuid}"))
    assert html_response(conn, 200) =~ comment.text
  end

  test "GET /comments/:uuid with not existing comment", %{conn: conn} do
    conn = get(conn, ~p"/comments/not_existing_comment")
    assert html_response(conn, 404)
  end

  test "GET /comments/:uuid with comment not public", %{conn: conn} do
    comment = insert(:comment, visibility: :private)
    conn = get(conn, url(~p"/comments/#{comment.uuid}"))
    assert html_response(conn, 404)
  end
end
