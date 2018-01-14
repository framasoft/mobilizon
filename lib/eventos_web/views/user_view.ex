defmodule EventosWeb.UserView do
  @moduledoc """
  View for Users
  """
  use EventosWeb, :view
  alias EventosWeb.UserView
  alias EventosWeb.AccountView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user_simple.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("show_simple.json", %{user: user}) do
    %{data: render_one(user, UserView, "user_simple.json")}
  end

  def render("show_with_token.json", %{user: user, token: token}) do
    %{
      user: render_one(user, UserView, "user_simple.json"),
      token: token
    }
  end

  def render("user_simple.json", %{user: user}) do
    %{id: user.id,
      role: user.role,
      account: render_one(user.account, AccountView, "account_for_user.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      role: user.role,
      account: render_one(user.account, AccountView, "account.json")
    }
  end

  def render("user_private.json", %{user: user}) do
    %{id: user.id,
      email: user.email,
      role: user.role,
    }
  end
end
