defmodule EventosWeb.ActivityPubController do
  use EventosWeb, :controller
  alias Eventos.{Actors, Actors.Actor, Events, Events.Event}
  alias EventosWeb.ActivityPub.{ObjectView, ActorView}
  alias Eventos.Service.ActivityPub
  alias Eventos.Service.Federator

  require Logger

  action_fallback(:errors)

  def actor(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("actor.json", %{actor: actor}))
    end
  end

  def event(conn, %{"uuid" => uuid}) do
    with %Event{} = event <- Events.get_event_full_by_uuid(uuid) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("event.json", %{event: event}))
    end
  end

  def following(conn, %{"name" => name, "page" => page}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      {page, _} = Integer.parse(page)

      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor, page: page}))
    end
  end

  def following(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor}))
    end
  end

  def followers(conn, %{"name" => name, "page" => page}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      {page, _} = Integer.parse(page)

      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor, page: page}))
    end
  end

  def followers(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
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

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if String.contains?(headers["signature"] || "", params["actor"]) do
      Logger.info("Signature error")
      Logger.info("Could not validate #{params["actor"]}")
      Logger.info(inspect(conn.req_headers))
    else
      Logger.info("Signature not from author, relayed message, fetching from source")
      ActivityPub.fetch_event_from_url(params["object"]["id"])
    end

    json(conn, "ok")
  end

  def errors(conn, _e) do
    conn
    |> put_status(500)
    |> json("error")
  end
end
