defmodule MobilizonWeb.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use MobilizonWeb, :controller
  plug(:put_layout, false)
  action_fallback(MobilizonWeb.FallbackController)

  def actor(conn, %{"name" => name, "format" => "atom"}) do
    case Cachex.fetch(:feed, "actor_" <> name) do
      {:commit, data} ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def actor(conn, %{"name" => name, "format" => "ics"}) do
    case Cachex.fetch(:ics, "actor_" <> name) do
      {:commit, data} ->
        conn
        |> put_resp_content_type("text/calendar")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def event(conn, %{"uuid" => uuid, "format" => "ics"}) do
    case Cachex.fetch(:ics, "event_" <> uuid) do
      {:commit, data} ->
        conn
        |> put_resp_content_type("text/calendar")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def going(conn, %{"token" => token, "format" => "ics"}) do
    case Cachex.fetch(:ics, "token_" <> token) do
      {:commit, data} ->
        conn
        |> put_resp_content_type("text/calendar")
        |> send_resp(200, data)

      _ ->
        {:error, :not_found}
    end
  end

  def going(conn, %{"token" => token, "format" => "atom"}) do
    case Cachex.fetch(:feed, "token_" <> token) do
      {:commit, data} ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> send_resp(200, data)

      {:ignore, _} ->
        {:error, :not_found}
    end
  end
end
