defmodule EventosWeb.GroupView do
  use EventosWeb, :view
  alias EventosWeb.GroupView

  def render("index.json", %{groups: groups}) do
    %{data: render_many(groups, GroupView, "group.json")}
  end

  def render("show.json", %{group: group}) do
    %{data: render_one(group, GroupView, "group.json")}
  end

  def render("group.json", %{group: group}) do
    %{id: group.id,
      title: group.title,
      description: group.description,
      suspended: group.suspended,
      url: group.url,
      uri: group.uri}
  end
end
