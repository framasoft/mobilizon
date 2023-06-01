defmodule Mobilizon.GraphQL.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Discussions, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment, as: CommentModel
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.Service.AntiSpam
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  alias Mobilizon.GraphQL.API.Comments

  require Logger

  @spec get_thread(any(), map(), Absinthe.Resolution.t()) :: {:ok, [CommentModel.t()]}
  def get_thread(_parent, %{id: thread_id}, _context) do
    {:ok, Discussions.get_thread_replies(thread_id)}
  end

  @spec create_comment(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, CommentModel.t()} | {:error, :unauthorized | :not_found | any() | String.t()}
  def create_comment(
        _parent,
        %{event_id: event_id} = args,
        %{
          context:
            %{
              current_actor: %Actor{id: actor_id, preferred_username: preferred_username},
              current_user: %User{email: email}
            } = context
        }
      ) do
    current_ip = Map.get(context, :ip)
    user_agent = Map.get(context, :user_agent, "")

    case Events.get_event(event_id) do
      {:ok,
       %Event{
         options: %EventOptions{comment_moderation: comment_moderation},
         organizer_actor_id: organizer_actor_id
       }} ->
        if comment_moderation != :closed || actor_id == organizer_actor_id do
          args = Map.put(args, :actor_id, actor_id)

          if AntiSpam.service().check_comment(
               args.text,
               preferred_username,
               !is_nil(Map.get(args, :in_reply_to_comment_id)),
               email,
               current_ip,
               user_agent
             ) == :ham do
            do_create_comment(args)
          else
            {:error,
             dgettext(
               "errors",
               "This comment was detected as spam."
             )}
          end
        else
          {:error, :unauthorized}
        end

      {:error, :event_not_found} ->
        {:error, :not_found}
    end
  end

  def create_comment(_parent, _args, _context) do
    {:error, dgettext("errors", "You are not allowed to create a comment if not connected")}
  end

  @spec do_create_comment(map()) ::
          {:ok, CommentModel.t()} | {:error, :entity_tombstoned | atom() | Ecto.Changeset.t()}
  defp do_create_comment(args) do
    case Comments.create_comment(args) do
      {:ok, _, %CommentModel{} = comment} ->
        {:ok, comment}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec update_comment(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, CommentModel.t()} | {:error, :unauthorized | :not_found | any() | String.t()}
  def update_comment(
        _parent,
        %{text: text, comment_id: comment_id},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    case Mobilizon.Discussions.get_comment_with_preload(comment_id) do
      %CommentModel{actor_id: comment_actor_id} = comment ->
        if actor_id == comment_actor_id do
          case Comments.update_comment(comment, %{text: text}) do
            {:ok, _, %CommentModel{} = comment} ->
              {:ok, comment}

            {:error, err} ->
              {:error, err}
          end
        else
          {:error, dgettext("errors", "You are not the comment creator")}
        end

      nil ->
        {:error, :not_found}
    end
  end

  def update_comment(_parent, _args, _context) do
    {:error, dgettext("errors", "You are not allowed to update a comment if not connected")}
  end

  def delete_comment(
        _parent,
        %{comment_id: comment_id},
        %{
          context: %{
            current_user: %User{role: role},
            current_actor: %Actor{id: actor_id} = actor
          }
        }
      ) do
    case Discussions.get_comment_with_preload(comment_id) do
      %CommentModel{deleted_at: nil} = comment ->
        cond do
          {:comment_can_be_managed, true} ==
              {:comment_can_be_managed, CommentModel.can_be_managed_by?(comment, actor_id)} ->
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

      %CommentModel{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, dgettext("errors", "Comment is already deleted")}

      nil ->
        {:error, dgettext("errors", "Comment not found")}
    end
  end

  def delete_comment(_parent, _args, %{}) do
    {:error, dgettext("errors", "You are not allowed to delete a comment if not connected")}
  end

  @spec do_delete_comment(CommentModel.t(), Actor.t()) ::
          {:ok, CommentModel.t()} | {:error, any()}
  defp do_delete_comment(%CommentModel{} = comment, %Actor{} = actor) do
    case Comments.delete_comment(comment, actor) do
      {:ok, _, %CommentModel{} = comment} ->
        {:ok, comment}

      {:error, err} ->
        {:error, err}
    end
  end
end
