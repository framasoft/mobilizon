defmodule Mobilizon.Web.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use Mobilizon.Web, :controller
  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)
  alias Mobilizon.Config

  def instance(conn, %{"format" => format}) do
    if Config.get([:instance, :enable_instance_feeds], false) do
      return_data(conn, format, "instance", Config.instance_name())
    else
      send_resp(conn, 401, "Instance feeds are not enabled.")
    end
  end

  def actor(conn, %{"format" => format, "name" => name}) do
    return_data(conn, format, "actor_" <> name, name)
  end

  def actor(_conn, _) do
    {:error, :not_found}
  end

  def event(conn, %{"uuid" => uuid, "format" => "ics"}) do
    return_data(conn, "ics", "event_" <> uuid, "event")
  end

  def event(_conn, _) do
    {:error, :not_found}
  end

  def going(conn, %{"token" => token, "format" => format}) do
    return_data(conn, format, "token_" <> token, "events")
  end

  def going(_conn, _) do
    {:error, :not_found}
  end

  defp return_data(conn, "atom", type, filename) do
    case Cachex.fetch(:feed, type) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{filename}.atom\""
        )
        |> send_resp(200, data)

      _err ->
        {:error, :not_found}
    end
  end

  defp return_data(conn, "ics", type, filename) do
    case Cachex.fetch(:ics, type) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{filename}.ics\""
        )
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  defp return_data(_conn, _, _, _) do
    {:error, :not_found}
  end
end
