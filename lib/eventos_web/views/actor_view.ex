defmodule EventosWeb.ActorView do
  @moduledoc """
  View for Actors
  """
  use EventosWeb, :view
  alias EventosWeb.{ActorView, EventView}

  def render("index.json", %{actors: actors}) do
    %{data: render_many(actors, ActorView, "acccount_basic.json")}
  end

  def render("show.json", %{actor: actor}) do
    %{data: render_one(actor, ActorView, "actor.json")}
  end

  def render("show_basic.json", %{actor: actor}) do
    %{data: render_one(actor, ActorView, "actor_basic.json")}
  end

  def render("acccount_basic.json", %{actor: actor}) do
    %{id: actor.id,
      username: actor.preferred_username,
      domain: actor.domain,
      display_name: actor.name,
      description: actor.summary,
      type: actor.type,
      # public_key: actor.public_key,
      suspended: actor.suspended,
      url: actor.url,
    }
  end

  def render("actor.json", %{actor: actor}) do
    %{id: actor.id,
      username: actor.preferred_username,
      domain: actor.domain,
      display_name: actor.name,
      description: actor.summary,
      type: actor.type,
      # public_key: actor.public_key,
      suspended: actor.suspended,
      url: actor.url,
      organized_events: render_many(actor.organized_events, EventView, "event_for_actor.json")
    }
  end
end
