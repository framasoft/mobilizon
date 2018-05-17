defmodule EventosWeb.OutboxesController do

  use EventosWeb, :controller

  def show(conn) do
    account = Guardian.Plug.current_resource(conn).account
    events = account.events

    render(conn, "index.json", events: events)
  end
end
