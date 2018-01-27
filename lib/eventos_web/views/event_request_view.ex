defmodule EventosWeb.EventRequestView do
  @moduledoc """
  View for Event Requests
  """
  use EventosWeb, :view
  alias EventosWeb.EventRequestView

  def render("index.json", %{event_requests: event_requests}) do
    %{data: render_many(event_requests, EventRequestView, "event_request.json")}
  end

  def render("show.json", %{event_request: event_request}) do
    %{data: render_one(event_request, EventRequestView, "event_request.json")}
  end

  def render("event_request.json", %{event_request: event_request}) do
    %{
      id: event_request.id,
      state: event_request.state,
      event: render_one(event_request.event, EventView, "event.json"),
      account: render_one(event_request.account, AccountView, "account.json")
    }
  end
end
