defmodule MobilizonWeb.API.Comments do
  @moduledoc """
  API for Comments.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Comment
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils

  alias MobilizonWeb.API.Utils

  @doc """
  Create a comment

  Creates a comment from an actor and a status
  """
  @spec create_comment(String.t(), String.t(), String.t()) ::
          {:ok, Activity.t(), Comment.t()} | any()
  def create_comment(
        from_username,
        status,
        visibility \\ :public,
        in_reply_to_comment_URL \\ nil
      ) do
    with {:local_actor, %Actor{url: url} = actor} <-
           {:local_actor, Actors.get_local_actor_by_name(from_username)},
         in_reply_to_comment <- get_in_reply_to_comment(in_reply_to_comment_URL),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(actor, status, visibility, [], in_reply_to_comment),
         comment <-
           ActivityPubUtils.make_comment_data(
             url,
             to,
             content_html,
             in_reply_to_comment,
             tags,
             cc
           ) do
      ActivityPub.create(%{
        to: to,
        actor: actor,
        object: comment,
        local: true
      })
    end
  end

  @spec get_in_reply_to_comment(nil) :: nil
  defp get_in_reply_to_comment(nil), do: nil
  @spec get_in_reply_to_comment(String.t()) :: Comment.t()
  defp get_in_reply_to_comment(in_reply_to_comment_url) do
    ActivityPub.fetch_object_from_url(in_reply_to_comment_url)
  end
end
