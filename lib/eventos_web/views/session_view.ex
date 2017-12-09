defmodule EventosWeb.SessionView do
  use EventosWeb, :view

  def render("token.json", %{token: token}) do
    %{token: token}
  end
end
