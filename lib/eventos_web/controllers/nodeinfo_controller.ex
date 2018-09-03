defmodule EventosWeb.NodeinfoController do
  use EventosWeb, :controller

  alias EventosWeb
  alias Eventos.{Actors, Events}

  @instance Application.get_env(:eventos, :instance)

  def schemas(conn, _params) do
    response = %{
      links: [
        %{
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
          href: EventosWeb.Router.Helpers.nodeinfo_url(EventosWeb.Endpoint, :nodeinfo, "2.0")
        }
      ]
    }

    json(conn, response)
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.0/schema.json
  def nodeinfo(conn, %{"version" => "2.0"}) do
    import Logger
    Logger.debug(inspect(@instance))
    # stats = Stats.get_stats()

    response = %{
      version: "2.0",
      software: %{
        name: "eventos",
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
          # total: stats.user_count || 0
          total: Actors.count_users()
        },
        localPosts: Events.count_local_events(),
        localComments: Events.count_local_comments()
        # localPosts: stats.status_count || 0
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
