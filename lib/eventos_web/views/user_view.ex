defmodule EventosWeb.UserView do
  use EventosWeb, :view
  import Logger

  def render("user.json", %{"user": user}) do
    %{
      email: user.email,
      account: render_one(user.account, EventosWeb.AccountView, "account.json"),
    }
  end
end
