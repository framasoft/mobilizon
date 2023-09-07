defmodule Mobilizon.Web.AuthView do
  @moduledoc """
  View for the auth routes
  """

  use Mobilizon.Web, :view
  alias Mobilizon.Service.Metadata.Instance
  alias Mobilizon.Web.PageView
  alias Phoenix.HTML.Tag

  @spec render(String.t(), map()) :: String.t() | Plug.Conn.t()
  def render(
        "callback.html",
        %{
          conn: _conn,
          access_token: access_token,
          refresh_token: refresh_token,
          user: %{
            id: user_id,
            email: user_email,
            role: user_role,
            default_actor_id: user_actor_id
          },
          username: username,
          name: name
        } = assigns
      ) do
    info_tags = [
      Tag.tag(:meta, name: "auth-access-token", content: access_token),
      Tag.tag(:meta, name: "auth-refresh-token", content: refresh_token),
      Tag.tag(:meta, name: "auth-user-id", content: user_id),
      Tag.tag(:meta, name: "auth-user-email", content: user_email),
      Tag.tag(:meta, name: "auth-user-role", content: String.upcase(to_string(user_role))),
      Tag.tag(:meta, name: "auth-user-actor-id", content: user_actor_id),
      Tag.tag(:meta, name: "auth-user-suggested-actor-username", content: username),
      Tag.tag(:meta, name: "auth-user-suggested-actor-name", content: name)
    ]

    with tags <- Instance.build_tags() ++ info_tags,
         assigns <- Map.put(assigns, :tags, tags) do
      PageView.render("index.html", assigns)
    end
  end
end
