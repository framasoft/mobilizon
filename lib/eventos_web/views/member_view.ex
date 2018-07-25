defmodule EventosWeb.MemberView do
  @moduledoc """
  View for Members
  """
  use EventosWeb, :view
  alias EventosWeb.{MemberView, ActorView}

  def render("index.json", %{members: members}) do
    %{data: render_many(members, MemberView, "member.json")}
  end

  def render("show.json", %{member: member}) do
    %{data: render_one(member, MemberView, "member.json")}
  end

  def render("member.json", %{member: member}) do
    %{
      role: member.role,
      actor: render_one(member.actor, ActorView, "actor_basic.json"),
      group: render_one(member.parent, ActorView, "actor_basic.json")
    }
  end
end
