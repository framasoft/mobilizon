defmodule MobilizonWeb.API.Comments do
  @moduledoc """
  API for Comments.
  """
  alias Mobilizon.Events.Comment
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Activity

  @doc """
  Create a comment

  Creates a comment from an actor and a status
  """
  @spec create_comment(map()) ::
          {:ok, Activity.t(), Comment.t()} | any()
  def create_comment(args) do
    ActivityPub.create(:comment, args, true)
  end
end
