defmodule EventosWeb.EventView do
  @moduledoc """
  View for Events
  """
  use EventosWeb, :view
  alias EventosWeb.{EventView, AccountView, GroupView}

  def render("index.json", %{events: events}) do
    %{data: render_many(events, EventView, "event_simple.json")}
  end

  def render("show_simple.json", %{event: event}) do
    %{data: render_one(event, EventView, "event_simple.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, EventView, "event.json")}
  end

  def render("event_simple.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
    }
  end

  def render("event.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
      organizer: render_one(event.organizer_account, AccountView, "acccount_basic.json"),
      group: render_one(event.organizer_group, GroupView, "group_basic.json"),
      participants: render_many(event.participants, AccountView, "show_basic.json"),
    }
  end
end
