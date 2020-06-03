defmodule Mobilizon.GraphQL.API.Comments do
  @moduledoc """
  API for Comments.
  """

  alias Mobilizon.Conversations.Comment

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity

  @doc """
  Create a comment

  Creates a comment from an actor
  """
  @spec create_comment(map) :: {:ok, Activity.t(), Comment.t()} | any
  def create_comment(args) do
    ActivityPub.create(:comment, args, true)
  end

  def update_comment(%Comment{} = comment, args) do
    ActivityPub.update(:comment, comment, args, true)
  end

  @doc """
  Deletes a comment

  Deletes a comment from an actor
  """
  @spec delete_comment(Comment.t()) :: {:ok, Activity.t(), Comment.t()} | any
  def delete_comment(%Comment{} = comment) do
    ActivityPub.delete(comment, true)
  end
end
