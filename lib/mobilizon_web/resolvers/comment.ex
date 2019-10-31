defmodule MobilizonWeb.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls.
  """

  alias Mobilizon.Events.Comment
  alias Mobilizon.Users.User
  alias Mobilizon.Actors.Actor

  alias MobilizonWeb.API.Comments

  require Logger

  def create_comment(_parent, %{text: text, actor_id: actor_id}, %{
        context: %{current_user: %User{} = user}
      }) do
    with {:is_owned, %Actor{} = _organizer_actor} <- User.owns_actor(user, actor_id),
         {:ok, _, %Comment{} = comment} <-
           Comments.create_comment(%{actor_id: actor_id, text: text}) do
      {:ok, comment}
    end
  end

  def create_comment(_parent, _args, %{}) do
    {:error, "You are not allowed to create a comment if not connected"}
  end
end
