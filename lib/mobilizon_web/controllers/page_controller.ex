defmodule MobilizonWeb.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use MobilizonWeb, :controller
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Comment}

  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params) do
    render(conn, "app.html")
  end

  def actor(conn, %{"name" => name}) do
    case get_format(conn) do
      "html" ->
        with {status, %Actor{} = actor} when status in [:ok, :commit] <-
               Actors.get_cached_local_actor_by_name(name) do
          render_with_meta(conn, actor)
        else
          _ -> {:error, :not_found}
        end

      # "activity-json" matches "application/activity+json" inside our config
      "activity-json" ->
        MobilizonWeb.ActivityPubController.call(conn, :actor)

      _ ->
        {:error, :not_found}
    end
  end

  def event(conn, %{"uuid" => uuid}) do
    case get_format(conn) do
      "html" ->
        with {status, %Event{} = event} when status in [:ok, :commit] <-
               Events.get_cached_event_full_by_uuid(uuid),
             true <- event.visibility in [:public, :unlisted] do
          render_with_meta(conn, event)
        else
          _ -> {:error, :not_found}
        end

      "activity-json" ->
        MobilizonWeb.ActivityPubController.call(conn, :event)

      _ ->
        {:error, :not_found}
    end
  end

  def comment(conn, %{"uuid" => uuid}) do
    case get_format(conn) do
      "html" ->
        with {status, %Comment{} = comment} when status in [:ok, :commit] <-
               Events.get_cached_comment_full_by_uuid(uuid),
             true <- comment.visibility in [:public, :unlisted] do
          render_with_meta(conn, comment)
        else
          _ -> {:error, :not_found}
        end

      "activity-json" ->
        MobilizonWeb.ActivityPubController.call(conn, :comment)

      _ ->
        {:error, :not_found}
    end
  end

  # Inject OpenGraph information
  defp render_with_meta(conn, object) do
    render(conn, "app.html", object: object)
  end
end
