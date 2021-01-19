defmodule Mobilizon.Web.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use Mobilizon.Web, :controller
  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)

  def actor(conn, %{"name" => name, "format" => "atom"}) do
    case Cachex.fetch(:feed, "actor_" <> name) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{name}.atom\"")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def actor(conn, %{"name" => name, "format" => "ics"}) do
    case Cachex.fetch(:ics, "actor_" <> name) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{name}.ics\"")
        |> send_resp(200, data)

      _err ->
        {:error, :not_found}
    end
  end

  def actor(_conn, _) do
    {:error, :not_found}
  end

  def event(conn, %{"uuid" => uuid, "format" => "ics"}) do
    case Cachex.fetch(:ics, "event_" <> uuid) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename=\"event.ics\"")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def event(_conn, _) do
    {:error, :not_found}
  end

  def going(conn, %{"token" => token, "format" => "ics"}) do
    case Cachex.fetch(:ics, "token_" <> token) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename=\"events.ics\"")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def going(conn, %{"token" => token, "format" => "atom"}) do
    case Cachex.fetch(:feed, "token_" <> token) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> put_resp_header("content-disposition", "attachment; filename=\"events.atom\"")
        |> send_resp(200, data)

      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  def going(_conn, _) do
    {:error, :not_found}
  end
end
