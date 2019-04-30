defmodule MobilizonWeb.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use MobilizonWeb, :controller
  action_fallback(MobilizonWeb.FallbackController)

  def actor(conn, %{"name" => name, "format" => "atom"}) do
    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:feed, "actor_" <> name) do
      conn
      |> put_resp_content_type("application/atom+xml")
      |> send_resp(200, data)
    else
      _err ->
        {:error, :not_found}
    end
  end

  def actor(conn, %{"name" => name, "format" => "ics"}) do
    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:ics, "actor_" <> name) do
      conn
      |> put_resp_content_type("text/calendar")
      |> send_resp(200, data)
    else
      _err ->
        {:error, :not_found}
    end
  end

  def event(conn, %{"uuid" => uuid, "format" => "ics"}) do
    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:ics, "event_" <> uuid) do
      conn
      |> put_resp_content_type("text/calendar")
      |> send_resp(200, data)
    else
      _err ->
        {:error, :not_found}
    end
  end

  def going(conn, %{"token" => token, "format" => "ics"}) do
    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:ics, "token_" <> token) do
      conn
      |> put_resp_content_type("text/calendar")
      |> send_resp(200, data)
    else
      _err ->
        {:error, :not_found}
    end
  end

  def going(conn, %{"token" => token, "format" => "atom"}) do
    with {status, data} when status in [:ok, :commit] <-
           Cachex.fetch(:feed, "token_" <> token) do
      conn
      |> put_resp_content_type("application/atom+xml")
      |> send_resp(200, data)
    else
      _err ->
        {:error, :not_found}
    end
  end
end
