defmodule MobilizonWeb.UserSessionView do
  @moduledoc """
  View for user Sessions
  """
  use MobilizonWeb, :view

  def render("token.json", %{token: token, user: user}) do
    %{token: token, user: render_one(user, MobilizonWeb.UserView, "user_simple.json")}
  end
end
