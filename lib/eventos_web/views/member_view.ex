defmodule EventosWeb.MemberView do
  @moduledoc """
  View for Members
  """
  use EventosWeb, :view
  alias EventosWeb.MemberView

  def render("index.json", %{members: members}) do
    %{data: render_many(members, MemberView, "member.json")}
  end

  def render("show.json", %{member: member}) do
    %{data: render_one(member, MemberView, "member.json")}
  end

  def render("member.json", %{member: member}) do
    %{id: member.id,
      role: member.role}
  end
end
