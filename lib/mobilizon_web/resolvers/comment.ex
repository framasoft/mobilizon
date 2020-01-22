defmodule MobilizonWeb.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls.
  """

  import Mobilizon.Service.Admin.ActionLogService

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Comment, as: CommentModel
  alias Mobilizon.Users.User

  alias MobilizonWeb.API.Comments

  require Logger

  def get_thread(_parent, %{id: thread_id}, _context) do
    {:ok, Events.get_thread_replies(thread_id)}
  end

  def create_comment(_parent, %{actor_id: actor_id} = args, %{
        context: %{current_user: %User{} = user}
      }) do
    with {:is_owned, %Actor{} = _organizer_actor} <- User.owns_actor(user, actor_id),
         {:ok, _, %CommentModel{} = comment} <-
           Comments.create_comment(args) do
      {:ok, comment}
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end

  def create_comment(_parent, _args, _context) do
    {:error, "You are not allowed to create a comment if not connected"}
  end

  def delete_comment(_parent, %{actor_id: actor_id, comment_id: comment_id}, %{
        context: %{current_user: %User{role: role} = user}
      }) do
    with {actor_id, ""} <- Integer.parse(actor_id),
         {:is_owned, %Actor{} = _organizer_actor} <- User.owns_actor(user, actor_id),
         %CommentModel{} = comment <- Events.get_comment_with_preload(comment_id) do
      cond do
        {:comment_can_be_managed, true} == CommentModel.can_be_managed_by(comment, actor_id) ->
          do_delete_comment(comment)

        role in [:moderator, :administrator] ->
          with {:ok, res} <- do_delete_comment(comment),
               %Actor{} = actor <- Actors.get_actor(actor_id) do
            log_action(actor, "delete", comment)

            {:ok, res}
          end

        true ->
          {:error, "You cannot delete this comment"}
      end
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end

  def delete_comment(_parent, _args, %{}) do
    {:error, "You are not allowed to delete a comment if not connected"}
  end

  defp do_delete_comment(%CommentModel{} = comment) do
    with {:ok, _, %CommentModel{} = comment} <-
           Comments.delete_comment(comment) do
      {:ok, comment}
    end
  end
end
