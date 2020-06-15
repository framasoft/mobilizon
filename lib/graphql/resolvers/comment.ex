defmodule Mobilizon.GraphQL.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Conversations}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment, as: CommentModel
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.API.Comments

  require Logger

  def get_thread(_parent, %{id: thread_id}, _context) do
    {:ok, Conversations.get_thread_replies(thread_id)}
  end

  def create_comment(
        _parent,
        %{actor_id: actor_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
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

  def update_comment(
        _parent,
        %{text: text, comment_id: comment_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         %CommentModel{actor_id: comment_actor_id} = comment <-
           Mobilizon.Conversations.get_comment(comment_id),
         true <- actor_id === comment_actor_id,
         {:ok, _, %CommentModel{} = comment} <- Comments.update_comment(comment, %{text: text}) do
      {:ok, comment}
    end
  end

  def edit_comment(_parent, _args, _context) do
    {:error, "You are not allowed to update a comment if not connected"}
  end

  def delete_comment(
        _parent,
        %{actor_id: actor_id, comment_id: comment_id},
        %{
          context: %{
            current_user: %User{role: role} = user
          }
        }
      ) do
    with {actor_id, ""} <- Integer.parse(actor_id),
         {:is_owned, %Actor{} = _organizer_actor} <- User.owns_actor(user, actor_id),
         %CommentModel{deleted_at: nil} = comment <-
           Conversations.get_comment_with_preload(comment_id) do
      cond do
        {:comment_can_be_managed, true} == CommentModel.can_be_managed_by(comment, actor_id) ->
          do_delete_comment(comment)

        role in [:moderator, :administrator] ->
          with {:ok, res} <- do_delete_comment(comment),
               %Actor{} = actor <- Actors.get_actor(actor_id) do
            Admin.log_action(actor, "delete", comment)

            {:ok, res}
          end

        true ->
          {:error, "You cannot delete this comment"}
      end
    else
      %CommentModel{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, "Comment is already deleted"}

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
