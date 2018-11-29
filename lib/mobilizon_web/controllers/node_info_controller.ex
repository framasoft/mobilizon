defmodule MobilizonWeb.NodeInfoController do
  use MobilizonWeb, :controller

  alias Mobilizon.{Actors, Events}

  @instance Application.get_env(:mobilizon, :instance)

  def schemas(conn, _params) do
    response = %{
      links: [
        %{
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
          href: MobilizonWeb.Router.Helpers.node_info_url(MobilizonWeb.Endpoint, :nodeinfo, "2.0")
        }
      ]
    }

    json(conn, response)
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.0/schema.json
  def nodeinfo(conn, %{"version" => "2.0"}) do
    response = %{
      version: "2.0",
      software: %{
        name: "mobilizon",
        version: Keyword.get(@instance, :version)
      },
      protocols: ["activitypub"],
      services: %{
        inbound: [],
        outbound: []
      },
      openRegistrations: Keyword.get(@instance, :registrations_open),
      usage: %{
        users: %{
          total: Actors.count_users()
        },
        localPosts: Events.count_local_events(),
        localComments: Events.count_local_comments()
      },
      metadata: %{
        nodeName: Keyword.get(@instance, :name)
      }
    }

    conn
    |> put_resp_header(
      "content-type",
      "application/json; profile=http://nodeinfo.diaspora.software/ns/schema/2.0#; charset=utf-8"
    )
    |> json(response)
  end

  def nodeinfo(conn, _) do
    conn
    |> put_status(404)
    |> json(%{error: "Nodeinfo schema version not handled"})
  end
end
