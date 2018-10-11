defmodule MobilizonWeb.OutboxesController do
  use MobilizonWeb, :controller

  def show(conn) do
    actor = Guardian.Plug.current_resource(conn).actor
    events = actor.events

    render(conn, "index.json", events: events)
  end
end
