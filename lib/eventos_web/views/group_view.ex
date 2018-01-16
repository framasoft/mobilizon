defmodule EventosWeb.GroupView do
  @moduledoc """
  View for Groups
  """
  use EventosWeb, :view
  alias EventosWeb.{GroupView, AccountView}

  def render("index.json", %{groups: groups}) do
    %{data: render_many(groups, GroupView, "group_simple.json")}
  end

  def render("show.json", %{group: group}) do
    %{data: render_one(group, GroupView, "group.json")}
  end

  def render("show_simple.json", %{group: group}) do
    %{data: render_one(group, GroupView, "group_simple.json")}
  end

  def render("group_simple.json", %{group: group}) do
    %{id: group.id,
      title: group.title,
      description: group.description,
      suspended: group.suspended,
      url: group.url,
      uri: group.uri
    }
  end

  def render("group.json", %{group: group}) do
    %{id: group.id,
      title: group.title,
      description: group.description,
      suspended: group.suspended,
      url: group.url,
      uri: group.uri,
      members: render_many(group.members, AccountView, "acccount_basic.json"),
      events: render_many(group.organized_events, EventView, "event_simple.json")
    }
  end
end
