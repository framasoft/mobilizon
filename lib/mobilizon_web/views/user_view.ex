defmodule MobilizonWeb.UserView do
  @moduledoc """
  View for Users
  """
  use MobilizonWeb, :view
  alias MobilizonWeb.UserView
  alias MobilizonWeb.ActorView

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
    %{
      id: user.id,
      role: user.role,
      actors: render_many(user.actors, ActorView, "actor_basic.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, role: user.role, actors: render_many(user.actors, ActorView, "actor.json")}
  end

  def render("user_private.json", %{user: user}) do
    %{id: user.id, email: user.email, role: user.role}
  end

  def render("confirmation.json", %{user: user}) do
    %{
      email: user.email
    }
  end

  def render("password_reset.json", %{user: user}) do
    %{
      email: user.email
    }
  end
end
