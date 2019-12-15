# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub_controller.ex

defmodule MobilizonWeb.ActivityPubController do
  use MobilizonWeb, :controller

  alias Mobilizon.{Actors, Actors.Actor, Config}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.Federator

  alias MobilizonWeb.ActivityPub.ActorView
  alias MobilizonWeb.Cache

  require Logger

  action_fallback(:errors)

  plug(MobilizonWeb.Plugs.Federating when action in [:inbox, :relay])
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

  def following(conn, %{"name" => name, "page" => page}) do
    with {page, ""} <- Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor, page: page}))
    end
  end

  def following(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor}))
    end
  end

  def followers(conn, %{"name" => name, "page" => page}) do
    with {page, ""} <- Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor, page: page}))
    end
  end

  def followers(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_preload(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor}))
    end
  end

  def outbox(conn, %{"name" => name, "page" => page}) do
    with {page, ""} <- Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("outbox.json", %{actor: actor, page: page}))
    end
  end

  def outbox(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("outbox.json", %{actor: actor}))
    end
  end

  # TODO: Ensure that this inbox is a recipient of the message
  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
    Logger.debug("Got something with valid signature inside inbox")
    Federator.enqueue(:incoming_ap_doc, params)
    json(conn, "ok")
  end

  # only accept relayed Creates
  def inbox(conn, %{"type" => "Create"} = params) do
    Logger.info(
      "Signature missing or not from author, relayed Create message, fetching object from source"
    )

    ActivityPub.fetch_object_from_url(params["object"]["id"])

    json(conn, "ok")
  end

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if String.contains?(headers["signature"], params["actor"]) do
      Logger.error(
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
end
