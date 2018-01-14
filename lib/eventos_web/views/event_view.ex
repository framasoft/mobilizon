defmodule EventosWeb.EventView do
  @moduledoc """
  View for Events
  """
  use EventosWeb, :view
  alias EventosWeb.EventView

  def render("index.json", %{events: events}) do
    %{data: render_many(events, EventView, "event.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, EventView, "event.json")}
  end

  def render("event.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on}
  end
end
