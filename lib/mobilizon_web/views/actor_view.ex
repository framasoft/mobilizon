defmodule MobilizonWeb.ActorView do
  @moduledoc """
  View for Actors
  """
  use MobilizonWeb, :view
  alias MobilizonWeb.{ActorView, EventView, MemberView}
  alias Mobilizon.Actors

  def render("index.json", %{actors: actors}) do
    %{data: render_many(actors, ActorView, "actor_basic.json")}
  end

  def render("show.json", %{actor: actor}) do
    %{data: render_one(actor, ActorView, "actor.json")}
  end

  def render("show_basic.json", %{actor: actor}) do
    %{data: render_one(actor, ActorView, "actor_basic.json")}
  end

  def render("actor_basic.json", %{actor: actor}) do
    %{
      id: actor.id,
      username: actor.preferred_username,
      domain: actor.domain,
      display_name: actor.name,
      description: actor.summary,
      type: actor.type,
      # public_key: actor.public_key,
      suspended: actor.suspended,
      url: actor.url,
      avatar: actor.avatar_url
    }
  end

  def render("actor.json", %{actor: actor}) do
    output = %{
      id: actor.id,
      username: actor.preferred_username,
      domain: actor.domain,
      display_name: actor.name,
      description: actor.summary,
      type: actor.type,
      # public_key: actor.public_key,
      suspended: actor.suspended,
      url: actor.url,
      avatar: actor.avatar_url,
      banner: actor.banner_url,
      organized_events: render_many(actor.organized_events, EventView, "event_for_actor.json")
    }

    import Logger
    Logger.debug(inspect(actor.type))

    if actor.type == :Group do
      Logger.debug("I'm a group !")

      Map.put(
        output,
        :members,
        render_many(Actors.members_for_group(actor), MemberView, "member.json")
      )
    else
      Logger.debug("not a group")
      output
    end
  end
end
