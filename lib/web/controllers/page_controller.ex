defmodule Mobilizon.Web.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use Mobilizon.Web, :controller

  alias Mobilizon.Web.Cache

  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)

  def index(conn, _params), do: render(conn, :index)

  def actor(conn, %{"name" => name}) do
    {status, actor} = Cache.get_local_actor_by_name(name)
    render_or_error(conn, &ok_status?/2, status, :actor, actor)
  end

  def event(conn, %{"uuid" => uuid}) do
    {status, event} = Cache.get_public_event_by_uuid_with_preload(uuid)
    render_or_error(conn, &ok_status_and_is_visible?/2, status, :event, event)
  end

  def comment(conn, %{"uuid" => uuid}) do
    {status, comment} = Cache.get_comment_by_uuid_with_preload(uuid)
    render_or_error(conn, &ok_status_and_is_visible?/2, status, :comment, comment)
  end

  defp render_or_error(conn, check_fn, status, object_type, object) do
    if check_fn.(status, object) do
      case object do
        %Mobilizon.Tombstone{} ->
          conn
          |> put_status(:gone)
          |> render(object_type, object: object)

        _ ->
          render(conn, object_type, object: object)
      end
    else
      {:error, :not_found}
    end
  end

  defp is_visible?(%{visibility: v}), do: v in [:public, :unlisted]
  defp is_visible?(%Mobilizon.Tombstone{}), do: true

  defp ok_status?(status), do: status in [:ok, :commit]
  defp ok_status?(status, _), do: ok_status?(status)

  defp ok_status_and_is_visible?(status, o), do: ok_status?(status) and is_visible?(o)
end
