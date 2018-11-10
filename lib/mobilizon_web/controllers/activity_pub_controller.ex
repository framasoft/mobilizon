defmodule MobilizonWeb.ActivityPubController do
  use MobilizonWeb, :controller
  alias Mobilizon.{Actors, Actors.Actor, Events}
  alias Mobilizon.Events.{Event, Comment}
  alias MobilizonWeb.ActivityPub.{ObjectView, ActorView}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.Federator

  require Logger

  action_fallback(:errors)

  @activity_pub_headers [
    "application/activity+json",
    "application/activity+json, application/ld+json"
  ]

  def actor(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      cond do
        conn |> get_req_header("accept") |> is_ap_header() ->
          conn |> render_ap_actor(actor)

        true ->
          conn
          |> put_resp_content_type("text/html")
          |> send_file(200, "priv/static/index.html")
      end
    else
      nil -> {:error, :not_found}
    end
  end

  defp is_ap_header(ap_headers) do
    length(@activity_pub_headers -- ap_headers) < 2
  end

  defp render_ap_actor(conn, %Actor{} = actor) do
    conn
    |> put_resp_header("content-type", "application/activity+json")
    |> json(ActorView.render("actor.json", %{actor: actor}))
  end

  def event(conn, %{"uuid" => uuid}) do
    with %Event{} = event <- Events.get_event_full_by_uuid(uuid),
         true <- event.public do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("event.json", %{event: event}))
    else
      _ ->
        {:error, :not_found}
    end
  end

  def comment(conn, %{"uuid" => uuid}) do
    with %Comment{} = comment <- Events.get_comment_full_from_uuid(uuid) do
      # Comments are always public for now
      # TODO : Make comments maybe restricted
      # true <- comment.public do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("comment.json", %{comment: comment}))
    else
      _ ->
        {:error, :not_found}
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
      Logger.info(
        "Signature validation error for: #{params["actor"]}, make sure you are forwarding the HTTP Host header!"
      )

      Logger.info(inspect(conn.req_headers))
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
    |> json("error")
  end
end
