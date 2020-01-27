# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/nodeinfo/nodeinfo_controller.ex

defmodule Mobilizon.Web.NodeInfoController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Config
  alias Mobilizon.Service.Statistics

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @node_info_supported_versions ["2.0", "2.1"]
  @node_info_schema_uri "http://nodeinfo.diaspora.software/ns/schema/"

  def schemas(conn, _params) do
    links =
      @node_info_supported_versions
      |> Enum.map(fn version ->
        %{
          rel: @node_info_schema_uri <> version,
          href: Routes.node_info_url(Endpoint, :nodeinfo, version)
        }
      end)

    json(conn, %{
      links: links
    })
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.1/schema.json
  def nodeinfo(conn, %{"version" => version}) when version in @node_info_supported_versions do
    response = %{
      version: version,
      software: %{
        name: "Mobilizon",
        version: Config.instance_version()
      },
      protocols: ["activitypub"],
      services: %{
        inbound: [],
        outbound: ["atom1.0"]
      },
      openRegistrations: Config.instance_registrations_open?(),
      usage: %{
        users: %{
          total: Statistics.get_cached_value(:local_users)
        },
        localPosts: Statistics.get_cached_value(:local_events),
        localComments: Statistics.get_cached_value(:local_comments)
      },
      metadata: %{
        nodeName: Config.instance_name(),
        nodeDescription: Config.instance_description()
      }
    }

    response =
      if version == "2.1" do
        put_in(response, [:software, :repository], Config.instance_repository())
      else
        response
      end

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
