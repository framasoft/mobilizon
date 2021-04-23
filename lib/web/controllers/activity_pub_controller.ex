# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub_controller.ex

defmodule Mobilizon.Web.ActivityPubController do
  use Mobilizon.Web, :controller

  alias Mobilizon.{Actors, Config}
  alias Mobilizon.Actors.{Actor, Member}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.{Federator, Utils}

  alias Mobilizon.Web.ActivityPub.ActorView
  alias Mobilizon.Web.Cache
  alias Plug.Conn

  require Logger

  action_fallback(:errors)

  plug(Mobilizon.Web.Plugs.Federating when action in [:inbox, :relay])
  plug(:relay_active? when action in [:relay])

  def relay_active?(conn, _) do
    if Config.get([:instance, :allow_relay]) do
      conn
    else
      conn
      |> put_status(404)
      |> json("Not found")
      |> halt()
    end
  end

  def following(conn, args) do
    actor_collection(conn, "following", args)
  end

  def followers(conn, args) do
    actor_collection(conn, "followers", args)
  end

  def members(conn, args) do
    actor_collection(conn, "members", args)
  end

  def resources(conn, args) do
    actor_collection(conn, "resources", args)
  end

  def posts(conn, args) do
    actor_collection(conn, "posts", args)
  end

  def todos(conn, args) do
    actor_collection(conn, "todos", args)
  end

  def events(conn, args) do
    actor_collection(conn, "events", args)
  end

  def discussions(conn, args) do
    actor_collection(conn, "discussions", args)
  end

  @ok_statuses [:ok, :commit]
  @spec member(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def member(conn, %{"uuid" => uuid}) do
    with {status, %Member{parent: %Actor{} = group, actor: %Actor{domain: nil} = _actor} = member}
         when status in @ok_statuses <-
           Cache.get_member_by_uuid_with_preload(uuid),
         actor <- Map.get(conn.assigns, :actor),
         true <- actor_applicant_group_member?(group, actor) do
      json(
        conn,
        ActorView.render("member.json", %{
          member: member,
          actor_applicant: actor
        })
      )
    else
      {status, %Member{actor: %Actor{url: domain}, parent: %Actor{} = group, url: url}}
      when status in @ok_statuses and not is_nil(domain) ->
        with actor <- Map.get(conn.assigns, :actor),
             true <- actor_applicant_group_member?(group, actor) do
          redirect(conn, external: url)
        else
          _ ->
            conn
            |> put_status(404)
            |> json("Not found")
        end

      _ ->
        conn
        |> put_status(404)
        |> json("Not found")
    end
  end

  def outbox(conn, args) do
    actor_collection(conn, "outbox", args)
  end

  def inbox(%{assigns: %{valid_signature: true}} = conn, %{"name" => preferred_username} = params) do
    with %Actor{url: recipient_url} = recipient <-
           Actors.get_local_actor_by_name(preferred_username),
         {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(params["actor"]),
         true <- Utils.recipient_in_message(recipient, actor, params),
         params <- Utils.maybe_splice_recipient(recipient_url, params) do
      Federator.enqueue(:incoming_ap_doc, params)
      json(conn, "ok")
    end
  end

  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
    Logger.debug("Got something with valid signature inside inbox")
    Federator.enqueue(:incoming_ap_doc, params)
    json(conn, "ok")
  end

  # only accept relayed Creates
  def inbox(conn, %{"type" => "Create"} = params) do
    Logger.debug(
      "Signature missing or not from author, relayed Create message, fetching object from source"
    )

    ActivityPub.fetch_object_from_url(params["object"]["id"])

    json(conn, "ok")
  end

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if headers["signature"] && params["actor"] &&
         String.contains?(headers["signature"], params["actor"]) do
      Logger.debug(
        "Signature validation error for: #{params["actor"]}, make sure you are forwarding the HTTP Host header!"
      )

      Logger.debug(inspect(conn.req_headers))
    end

    json(conn, "error")
  end

  def relay(conn, _params) do
    with {status, %Actor{} = actor} when status in [:commit, :ok] <- Cache.get_relay() do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("actor.json", %{actor: actor}))
    end
  end

  def errors(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json("Not found")
  end

  def errors(conn, e) do
    Logger.debug(inspect(e))

    conn
    |> put_status(500)
    |> json("Unknown Error")
  end

  @spec actor_collection(Conn.t(), String.t(), map()) :: Conn.t()

  defp actor_collection(conn, collection, %{"name" => name, "page" => page}) do
    with {page, ""} <- Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(
        ActorView.render("#{collection}.json", %{
          actor: actor,
          page: page,
          actor_applicant: Map.get(conn.assigns, :actor)
        })
      )
    end
  end

  defp actor_collection(conn, collection, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(
        ActorView.render("#{collection}.json", %{
          actor: actor,
          actor_applicant: Map.get(conn.assigns, :actor)
        })
      )
    end
  end

  defp actor_applicant_group_member?(%Actor{}, nil), do: false

  defp actor_applicant_group_member?(%Actor{id: group_id}, %Actor{id: actor_applicant_id}),
    do:
      Actors.get_member(actor_applicant_id, group_id, [
        :member,
        :moderator,
        :administrator,
        :creator
      ]) != {:error, :member_not_found}
end
