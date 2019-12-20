defmodule Mobilizon.Web.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use Mobilizon.Web, :controller

  alias Mobilizon.Events.{Comment, Event}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Cache

  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)

  def index(conn, _params), do: render(conn, :index)

  def actor(conn, %{"name" => name}) do
    {status, actor} = Cache.get_local_actor_by_name(name)
    render_or_error(conn, &ok_status?/3, status, :actor, actor)
  end

  def event(conn, %{"uuid" => uuid}) do
    {status, event} = Cache.get_public_event_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :event, event)
  end

  def comment(conn, %{"uuid" => uuid}) do
    {status, comment} = Cache.get_comment_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :comment, comment)
  end

  def interact(conn, %{"uri" => uri}) do
    case ActivityPub.fetch_object_from_url(uri) do
      {:ok, %Event{uuid: uuid}} -> redirect(conn, to: "/events/#{uuid}")
      {:ok, %Comment{uuid: uuid}} -> redirect(conn, to: "/comments/#{uuid}")
      _ -> {:error, :not_found}
    end
  end

  defp render_or_error(conn, check_fn, status, object_type, object) do
    case check_fn.(conn, status, object) do
      true ->
        case object do
          %Tombstone{} ->
            conn
            |> put_status(:gone)
            |> render(object_type, object: object)

          _ ->
            render(conn, object_type, object: object)
        end

      :remote ->
        redirect(conn, external: object.url)

      false ->
        {:error, :not_found}
    end
  end

  defp is_visible?(%{visibility: v}), do: v in [:public, :unlisted]
  defp is_visible?(%Tombstone{}), do: true

  defp ok_status?(status), do: status in [:ok, :commit]
  defp ok_status?(_conn, status, _), do: ok_status?(status)

  defp ok_status_and_is_visible?(_conn, status, o),
    do: ok_status?(status) and is_visible?(o)

  defp checks?(conn, status, o) do
    if ok_status_and_is_visible?(conn, status, o) do
      if is_local?(o) == :remote && get_format(conn) == "activity-json", do: :remote, else: true
    else
      false
    end
  end

  defp is_local?(%Event{local: local}), do: if(local, do: true, else: :remote)
  defp is_local?(%Comment{local: local}), do: if(local, do: true, else: :remote)
end
