# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/nodeinfo/nodeinfo_controller.ex

defmodule Mobilizon.Web.NodeInfoController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Config
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.Statistics

  @node_info_supported_versions ["2.0", "2.1"]
  @node_info_schema_uri "http://nodeinfo.diaspora.software/ns/schema/"
  @application_uri "https://www.w3.org/ns/activitystreams#Application"

  @spec schemas(Plug.Conn.t(), any) :: Plug.Conn.t()
  def schemas(conn, _params) do
    relay = Relay.get_actor()

    links =
      @node_info_supported_versions
      |> Enum.map(fn version ->
        %{
          rel: @node_info_schema_uri <> version,
          href: url(~p"/.well-known/nodeinfo/#{version}")
        }
      end)
      |> Kernel.++([
        %{
          rel: @application_uri,
          href: relay.url
        }
      ])

    json(conn, %{
      links: links
    })
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.1/schema.json
  @spec nodeinfo(Plug.Conn.t(), any()) :: Plug.Conn.t()
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
