defmodule EventosWeb.SessionView do
  use EventosWeb, :view

  def render("token.json", %{token: token, user: user}) do
    %{token: token, user: render_one(user, EventosWeb.UserView, "user.json")}
  end
end
