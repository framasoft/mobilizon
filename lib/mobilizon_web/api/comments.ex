defmodule MobilizonWeb.API.Comments do
  @moduledoc """
  API for Comments
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Comment
  alias Mobilizon.Service.Formatter
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  import MobilizonWeb.API.Utils

  @doc """
  Create a comment

  Creates a comment from an actor and a status
  """
  @spec create_comment(String.t(), String.t(), String.t()) :: {:ok, Activity.t()} | any()
  def create_comment(
        from_username,
        status,
        visibility \\ "public",
        in_reply_to_comment_URL \\ nil
      ) do
    with {:local_actor, %Actor{url: url} = actor} <-
           {:local_actor, Actors.get_local_actor_by_name(from_username)},
         status <- String.trim(status),
         mentions <- Formatter.parse_mentions(status),
         in_reply_to_comment <- get_in_reply_to_comment(in_reply_to_comment_URL),
         {to, cc} <- to_for_actor_and_mentions(actor, mentions, in_reply_to_comment, visibility),
         tags <- Formatter.parse_tags(status),
         content_html <-
           make_content_html(
             status,
             mentions,
             tags,
             "text/plain"
           ),
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
