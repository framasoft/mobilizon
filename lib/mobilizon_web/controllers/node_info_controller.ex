# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/nodeinfo/nodeinfo_controller.ex

defmodule MobilizonWeb.NodeInfoController do
  use MobilizonWeb, :controller

  alias Mobilizon.{Events, Users}

  @instance Application.get_env(:mobilizon, :instance)

  def schemas(conn, _params) do
    response = %{
      links: [
        %{
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
          href: MobilizonWeb.Router.Helpers.node_info_url(MobilizonWeb.Endpoint, :nodeinfo, "2.1")
        }
      ]
    }

    json(conn, response)
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.1/schema.json
  def nodeinfo(conn, %{"version" => "2.1"}) do
    response = %{
      version: "2.1",
      software: %{
        name: "mobilizon",
        version: Keyword.get(@instance, :version),
        repository: Keyword.get(@instance, :repository)
      },
      protocols: ["activitypub"],
      services: %{
        inbound: [],
        outbound: []
      },
      openRegistrations: Keyword.get(@instance, :registrations_open),
      usage: %{
        users: %{
          total: Users.count_users()
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
      "application/json; profile=http://nodeinfo.diaspora.software/ns/schema/2.1#; charset=utf-8"
    )
    |> json(response)
  end

  def nodeinfo(conn, _) do
    conn
    |> put_status(404)
    |> json(%{error: "Nodeinfo schema version not handled"})
  end
end
