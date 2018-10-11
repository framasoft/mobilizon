defmodule MobilizonWeb.NodeinfoControllerTest do
  use MobilizonWeb.ConnCase

  @instance Application.get_env(:mobilizon, :instance)

  test "Get node info schemas", %{conn: conn} do
    conn = get(conn, nodeinfo_path(conn, :schemas))

    assert json_response(conn, 200) == %{
             "links" => [
               %{
                 "href" =>
                   MobilizonWeb.Router.Helpers.nodeinfo_url(MobilizonWeb.Endpoint, :nodeinfo, "2.0"),
                 "rel" => "http://nodeinfo.diaspora.software/ns/schema/2.0"
               }
             ]
           }
  end

  test "Get node info", %{conn: conn} do
    conn = get(conn, nodeinfo_path(conn, :nodeinfo, "2.0"))

    resp = json_response(conn, 200)

    assert resp = %{
             "metadata" => %{"nodeName" => Keyword.get(@instance, :name)},
             "openRegistrations" => Keyword.get(@instance, :registrations_open),
             "protocols" => ["activitypub"],
             "services" => %{"inbound" => [], "outbound" => []},
             "software" => %{"name" => "mobilizon", "version" => Keyword.get(@instance, :version)},
             "version" => "2.0"
           }
  end
end
