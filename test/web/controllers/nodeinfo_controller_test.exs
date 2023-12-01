defmodule Mobilizon.Web.NodeInfoControllerTest do
  use Mobilizon.Web.ConnCase

  alias Mobilizon.Config

  use Mobilizon.Web, :verified_routes

  test "Get node info schemas", %{conn: conn} do
    conn = get(conn, url(~p"/.well-known/nodeinfo"))

    assert json_response(conn, 200) == %{
             "links" => [
               %{
                 "href" => url(~p"/.well-known/nodeinfo/2.0"),
                 "rel" => "http://nodeinfo.diaspora.software/ns/schema/2.0"
               },
               %{
                 "href" => url(~p"/.well-known/nodeinfo/2.1"),
                 "rel" => "http://nodeinfo.diaspora.software/ns/schema/2.1"
               }
             ]
           }
  end

  test "Get node info", %{conn: conn} do
    # We clear the cache because it might have been initialized by other tests
    Cachex.clear(:statistics)
    conn = get(conn, url(~p"/.well-known/nodeinfo/2.1"))
    resp = json_response(conn, 200)

    assert resp == %{
             "metadata" => %{
               "nodeName" => Config.instance_name(),
               "nodeDescription" => Config.instance_description()
             },
             "openRegistrations" => Config.instance_registrations_open?(),
             "protocols" => ["activitypub"],
             "services" => %{"inbound" => [], "outbound" => ["atom1.0"]},
             "software" => %{
               "name" => "Mobilizon",
               "version" => Config.instance_version(),
               "repository" => Config.instance_repository()
             },
             "usage" => %{"localComments" => 0, "localPosts" => 0, "users" => %{"total" => 0}},
             "version" => "2.1"
           }
  end

  test "Get node info with non supported version (1.0)", %{conn: conn} do
    conn = get(conn, url(~p"/.well-known/nodeinfo/1.0"))

    assert json_response(conn, 404) == %{"error" => "Nodeinfo schema version not handled"}
  end
end
