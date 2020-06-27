defmodule Mobilizon.Web.AuthView do
  @moduledoc """
  View for the auth routes
  """

  use Mobilizon.Web, :view
  alias Mobilizon.Service.Metadata.Instance
  alias Phoenix.HTML.Tag
  import Mobilizon.Web.Views.Utils

  def render("callback.html", %{
        conn: conn,
        access_token: access_token,
        refresh_token: refresh_token,
        user: %{id: user_id, email: user_email, role: user_role, default_actor_id: user_actor_id}
      }) do
    info_tags = [
      Tag.tag(:meta, name: "auth-access-token", content: access_token),
      Tag.tag(:meta, name: "auth-refresh-token", content: refresh_token),
      Tag.tag(:meta, name: "auth-user-id", content: user_id),
      Tag.tag(:meta, name: "auth-user-email", content: user_email),
      Tag.tag(:meta, name: "auth-user-role", content: user_role),
      Tag.tag(:meta, name: "auth-user-actor-id", content: user_actor_id)
    ]

    tags = Instance.build_tags() ++ info_tags
    inject_tags(tags, get_locale(conn))
  end
end
