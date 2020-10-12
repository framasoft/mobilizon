defmodule Mobilizon.Web.PageController do
  @moduledoc """
  Controller to load our webapp
  """
  use Mobilizon.Web, :controller

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.{ActivityPubController, Cache, PageController}

  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)

  defdelegate my_events(conn, params), to: PageController, as: :index
  defdelegate create_event(conn, params), to: PageController, as: :index
  defdelegate list_events(conn, params), to: PageController, as: :index
  defdelegate edit_event(conn, params), to: PageController, as: :index
  defdelegate moderation_report(conn, params), to: PageController, as: :index
  defdelegate participation_email_confirmation(conn, params), to: PageController, as: :index
  defdelegate user_email_validation(conn, params), to: PageController, as: :index
  defdelegate my_groups(conn, params), to: PageController, as: :index

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params), do: render(conn, :index)

  @spec actor(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def actor(conn, %{"name" => name}) do
    {status, actor} = Cache.get_actor_by_name(name)
    render_or_error(conn, &checks?/3, status, :actor, actor)
  end

  @spec event(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def event(conn, %{"uuid" => uuid}) do
    {status, event} = Cache.get_public_event_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :event, event)
  end

  @spec comment(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def comment(conn, %{"uuid" => uuid}) do
    {status, comment} = Cache.get_comment_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :comment, comment)
  end

  @spec resource(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def resource(conn, %{"uuid" => uuid}) do
    {status, resource} = Cache.get_resource_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :resource, resource)
  end

  @spec post(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def post(conn, %{"slug" => slug}) do
    {status, post} = Cache.get_post_by_slug_with_preload(slug)
    render_or_error(conn, &checks?/3, status, :post, post)
  end

  @spec discussion(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def discussion(conn, %{"slug" => slug}) do
    {status, discussion} = Cache.get_discussion_by_slug_with_preload(slug)
    render_or_error(conn, &checks?/3, status, :discussion, discussion)
  end

  def resources(conn, %{"name" => _name}) do
    handle_collection_route(conn, :resources)
  end

  def posts(conn, %{"name" => _name}) do
    handle_collection_route(conn, :posts)
  end

  def discussions(conn, %{"name" => _name}) do
    handle_collection_route(conn, :discussions)
  end

  def events(conn, %{"name" => _name}) do
    handle_collection_route(conn, :events)
  end

  def todos(conn, %{"name" => _name}) do
    handle_collection_route(conn, :todos)
  end

  @spec todo_list(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def todo_list(conn, %{"uuid" => uuid}) do
    {status, todo_list} = Cache.get_todo_list_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :todo_list, todo_list)
  end

  @spec todo(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def todo(conn, %{"uuid" => uuid}) do
    {status, todo} = Cache.get_todo_by_uuid_with_preload(uuid)
    render_or_error(conn, &checks?/3, status, :todo, todo)
  end

  @spec interact(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def interact(conn, %{"uri" => uri}) do
    case ActivityPub.fetch_object_from_url(uri) do
      {:ok, %Event{uuid: uuid}} -> redirect(conn, to: "/events/#{uuid}")
      {:ok, %Comment{uuid: uuid}} -> redirect(conn, to: "/comments/#{uuid}")
      _ -> {:error, :not_found}
    end
  end

  defp handle_collection_route(conn, collection) do
    case get_format(conn) do
      "html" ->
        render(conn, :index)

      "activity-json" ->
        ActivityPubController.call(conn, collection)
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
            conn
            |> maybe_add_noindex_header(object)
            |> render(object_type, object: object)
        end

      :remote ->
        redirect(conn, external: object.url)

      false ->
        {:error, :not_found}
    end
  end

  defp is_visible?(%{visibility: v}), do: v in [:public, :unlisted]
  defp is_visible?(%Tombstone{}), do: true
  defp is_visible?(_), do: true

  defp ok_status?(status), do: status in [:ok, :commit]

  defp ok_status_and_is_visible?(_conn, status, o),
    do: ok_status?(status) and is_visible?(o)

  defp checks?(conn, status, o) do
    cond do
      ok_status_and_is_visible?(conn, status, o) ->
        if is_local?(o) == :remote && get_format(conn) == "activity-json", do: :remote, else: true

      is_person?(o) && get_format(conn) == "activity-json" ->
        true

      true ->
        false
    end
  end

  defp is_local?(%{local: local}), do: if(local, do: true, else: :remote)
  defp is_local?(_), do: false

  defp maybe_add_noindex_header(conn, %{visibility: visibility})
       when visibility != :public do
    put_resp_header(conn, "x-robots-tag", "noindex")
  end

  defp maybe_add_noindex_header(conn, _), do: conn

  defp is_person?(%Actor{type: :Person}), do: true
  defp is_person?(_), do: false
end
