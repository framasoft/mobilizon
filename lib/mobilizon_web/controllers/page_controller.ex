defmodule MobilizonWeb.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use MobilizonWeb, :controller
  alias Mobilizon.Actors
  alias Mobilizon.Events

  plug(:put_layout, false)
  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params), do: render(conn, :index)

  def actor(conn, %{"name" => name}) do
    {status, actor} = Actors.get_cached_local_actor_by_name(name)
    render_or_error(conn, &ok_status?/2, status, :actor, actor)
  end

  def event(conn, %{"uuid" => uuid}) do
    {status, event} = Events.get_cached_public_event_by_uuid_with_preload(uuid)
    render_or_error(conn, &ok_status_and_is_visible?/2, status, :event, event)
  end

  def comment(conn, %{"uuid" => uuid}) do
    {status, comment} = Events.get_cached_comment_by_uuid_with_preload(uuid)
    render_or_error(conn, &ok_status_and_is_visible?/2, status, :comment, comment)
  end

  defp render_or_error(conn, check_fn, status, object_type, object) do
    if check_fn.(status, object) do
      render(conn, object_type, object: object)
    else
      {:error, :not_found}
    end
  end

  defp is_visible?(%{visibility: v}), do: v in [:public, :unlisted]

  defp ok_status?(status), do: status in [:ok, :commit]
  defp ok_status?(status, _), do: ok_status?(status)

  defp ok_status_and_is_visible?(status, o), do: ok_status?(status) and is_visible?(o)
end
