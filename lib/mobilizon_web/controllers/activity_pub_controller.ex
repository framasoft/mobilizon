# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub_controller.ex

defmodule MobilizonWeb.ActivityPubController do
  use MobilizonWeb, :controller
  alias Mobilizon.{Actors, Actors.Actor, Events}
  alias Mobilizon.Events.{Event, Comment}
  alias MobilizonWeb.ActivityPub.{ObjectView, ActorView}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils
  alias Mobilizon.Service.Federator

  require Logger

  action_fallback(:errors)

  @activity_pub_headers [
    "application/activity+json",
    "application/activity+json, application/ld+json"
  ]

  @doc """
  Show an Actor's ActivityPub representation
  """
  @spec actor(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def actor(conn, %{"name" => name}) do
    if conn |> get_req_header("accept") |> is_ap_header() do
      render_cached_actor(conn, name)
    else
      conn
      |> put_resp_content_type("text/html")
      |> send_file(200, "priv/static/index.html")
    end
  end

  @spec render_cached_actor(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp render_cached_actor(conn, name) do
    case Cachex.fetch(:activity_pub, "actor_" <> name, &get_local_actor_by_name/1) do
      {status, %Actor{} = actor} when status in [:ok, :commit] ->
        conn
        |> put_resp_header("content-type", "application/activity+json")
        |> json(ActorView.render("actor.json", %{actor: actor}))

      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  defp get_local_actor_by_name("actor_" <> name) do
    case Actors.get_local_actor_by_name(name) do
      nil -> {:ignore, nil}
      %Actor{} = actor -> {:commit, actor}
    end
  end

  # Test if the request has an AP header
  defp is_ap_header(ap_headers) do
    length(@activity_pub_headers -- ap_headers) < 2
  end

  @doc """
  Renders an Event ActivityPub's representation
  """
  @spec event(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def event(conn, %{"uuid" => uuid}) do
    case Cachex.fetch(:activity_pub, "event_" <> uuid, &get_event_full_by_uuid/1) do
      {status, %Event{} = event} when status in [:ok, :commit] ->
        conn
        |> put_resp_header("content-type", "application/activity+json")
        |> json(ObjectView.render("event.json", %{event: event |> Utils.make_event_data()}))

      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  defp get_event_full_by_uuid("event_" <> uuid) do
    with %Event{} = event <- Events.get_event_full_by_uuid(uuid),
         true <- event.visibility in [:public, :unlisted] do
      {:commit, event}
    else
      _ -> {:ignore, nil}
    end
  end

  @doc """
  Renders a Comment ActivityPub's representation
  """
  @spec comment(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def comment(conn, %{"uuid" => uuid}) do
    case Cachex.fetch(:activity_pub, "comment_" <> uuid, &get_comment_full_by_uuid/1) do
      {status, %Comment{} = comment} when status in [:ok, :commit] ->
        conn
        |> put_resp_header("content-type", "application/activity+json")
        |> json(
          ObjectView.render("comment.json", %{comment: comment |> Utils.make_comment_data()})
        )

      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  defp get_comment_full_by_uuid("comment_" <> uuid) do
    with %Comment{} = comment <- Events.get_comment_full_from_uuid(uuid) do
      # Comments are always public for now
      # TODO : Make comments maybe restricted
      # true <- comment.public do
      {:commit, comment}
    else
      _ -> {:ignore, nil}
    end
  end

  def following(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor, page: page}))
    end
  end

  def following(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor}))
    end
  end

  def followers(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor, page: page}))
    end
  end

  def followers(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor}))
    end
  end

  def outbox(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("outbox.json", %{actor: actor, page: page}))
    end
  end

  def outbox(conn, %{"name" => username}) do
    outbox(conn, %{"name" => username, "page" => "0"})
  end

  # TODO: Ensure that this inbox is a recipient of the message
  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
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

      Logger.error(inspect(conn.req_headers))
    end

    json(conn, "error")
  end

  def errors(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json("Not found")
  end

  def errors(conn, _e) do
    conn
    |> put_status(500)
    |> json("Unknown Error")
  end
end
