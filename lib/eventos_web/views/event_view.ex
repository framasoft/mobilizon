defmodule EventosWeb.EventView do
  @moduledoc """
  View for Events
  """
  use EventosWeb, :view
  alias EventosWeb.{EventView, ActorView, GroupView, AddressView, ParticipantView}

  def render("index.json", %{events: events, coord: coord, city: city, country: country}) do
    %{
      data: render_many(events, EventView, "event_simple.json"),
      coord: coord,
      city: city,
      country: country
    }
  end

  def render("index_all.json", %{events: events}) do
    %{
      data: render_many(events, EventView, "event_simple.json")
    }
  end

  def render("show_simple.json", %{event: event}) do
    %{data: render_one(event, EventView, "event_simple.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, EventView, "event.json")}
  end

  def render("event_for_actor.json", %{event: event}) do
    %{id: event.id, title: event.title, uuid: event.uuid}
  end

  def render("event_simple.json", %{event: event}) do
    %{
      id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
      uuid: event.uuid,
      organizer: %{
        username: event.organizer_actor.preferred_username,
        display_name: event.organizer_actor.name,
        avatar: event.organizer_actor.avatar_url
      },
      type: "Event",
      address_type: event.address_type
    }
  end

  def render("event.json", %{event: event}) do
    %{
      id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
      uuid: event.uuid,
      organizer: render_one(event.organizer_actor, ActorView, "actor_basic.json"),
      participants: render_many(event.participants, ParticipantView, "participant.json"),
      physical_address: render_one(event.physical_address, AddressView, "address.json"),
      type: "Event",
      address_type: event.address_type
    }
  end
end
