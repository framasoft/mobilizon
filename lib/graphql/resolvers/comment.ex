defmodule Mobilizon.GraphQL.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Discussions, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment, as: CommentModel
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.GraphQL.API.Comments

  require Logger

  def get_thread(_parent, %{id: thread_id}, _context) do
    {:ok, Discussions.get_thread_replies(thread_id)}
  end

  def create_comment(
        _parent,
        %{event_id: event_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:find_event,
          {:ok,
           %Event{
             options: %EventOptions{comment_moderation: comment_moderation},
             organizer_actor_id: organizer_actor_id
           }}} <-
           {:find_event, Events.get_event(event_id)},
         {:allowed, true} <-
           {:allowed, comment_moderation != :closed || actor_id == organizer_actor_id},
         args <- Map.put(args, :actor_id, actor_id),
         {:ok, _, %CommentModel{} = comment} <-
           Comments.create_comment(args) do
      {:ok, comment}
    else
      {:allowed, false} ->
        {:error, :unauthorized}
    end
  end

  def create_comment(_parent, _args, _context) do
    {:error, dgettext("errors", "You are not allowed to create a comment if not connected")}
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
           Mobilizon.Discussions.get_comment_with_preload(comment_id),
         true <- actor_id === comment_actor_id,
         {:ok, _, %CommentModel{} = comment} <- Comments.update_comment(comment, %{text: text}) do
      {:ok, comment}
    end
  end

  def edit_comment(_parent, _args, _context) do
    {:error, dgettext("errors", "You are not allowed to update a comment if not connected")}
  end

  def delete_comment(
        _parent,
        %{comment_id: comment_id},
        %{
          context: %{
            current_user: %User{role: role} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = actor} <- {:actor, Users.get_actor_for_user(user)},
         %CommentModel{deleted_at: nil} = comment <-
           Discussions.get_comment_with_preload(comment_id) do
      cond do
        {:comment_can_be_managed, true} == CommentModel.can_be_managed_by(comment, actor_id) ->
          do_delete_comment(comment, actor)

        role in [:moderator, :administrator] ->
          with {:ok, res} <- do_delete_comment(comment, actor),
               %Actor{} = actor <- Actors.get_actor(actor_id) do
            Admin.log_action(actor, "delete", comment)

            {:ok, res}
          end

        true ->
          {:error, dgettext("errors", "You cannot delete this comment")}
      end
    else
      %CommentModel{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, dgettext("errors", "Comment is already deleted")}
    end
  end

  def delete_comment(_parent, _args, %{}) do
    {:error, dgettext("errors", "You are not allowed to delete a comment if not connected")}
  end

  defp do_delete_comment(%CommentModel{} = comment, %Actor{} = actor) do
    with {:ok, _, %CommentModel{} = comment} <-
           Comments.delete_comment(comment, actor) do
      {:ok, comment}
    end
  end
end
