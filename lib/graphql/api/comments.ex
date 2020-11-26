defmodule Mobilizon.GraphQL.API.Comments do
  @moduledoc """
  API for discussions and comments.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.GraphQL.API.Utils

  @doc """
  Create a comment
  """
  @spec create_comment(map) :: {:ok, Activity.t(), Comment.t()} | any
  def create_comment(args) do
    args = extract_pictures_from_comment_body(args)
    ActivityPub.create(:comment, args, true)
  end

  @doc """
  Updates a comment
  """
  @spec update_comment(Comment.t(), map()) :: {:ok, Activity.t(), Comment.t()} | any
  def update_comment(%Comment{} = comment, args) do
    args = extract_pictures_from_comment_body(args)
    ActivityPub.update(comment, args, true)
  end

  @doc """
  Deletes a comment
  """
  @spec delete_comment(Comment.t(), Actor.t()) :: {:ok, Activity.t(), Comment.t()} | any
  def delete_comment(%Comment{} = comment, %Actor{} = actor) do
    ActivityPub.delete(comment, actor, true)
  end

  @doc """
  Creates a discussion (or reply to a discussion)
  """
  @spec create_discussion(map()) :: map()
  def create_discussion(args) do
    args = extract_pictures_from_comment_body(args)

    ActivityPub.create(
      :discussion,
      args,
      true
    )
  end

  @spec extract_pictures_from_comment_body(map()) :: map()
  defp extract_pictures_from_comment_body(%{text: text, actor_id: actor_id} = args) do
    pictures = Utils.extract_pictures_from_body(text, actor_id)
    Map.put(args, :media, pictures)
  end

  defp extract_pictures_from_comment_body(args), do: args
end
