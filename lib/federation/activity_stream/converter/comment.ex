defmodule Mobilizon.Federation.ActivityStream.Converter.Comment do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions
  alias Mobilizon.Discussions.Comment, as: CommentModel
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Visibility
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Comment, as: CommentConverter
  alias Mobilizon.Tombstone, as: TombstoneModel

  import Mobilizon.Federation.ActivityStream.Converter.Utils,
    only: [
      fetch_tags: 1,
      fetch_mentions: 1,
      build_tags: 1,
      build_mentions: 1,
      maybe_fetch_actor_and_attributed_to_id: 1
    ]

  require Logger

  @behaviour Converter

  defimpl Convertible, for: CommentModel do
    defdelegate model_to_as(comment), to: CommentConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map | {:error, atom}
  def as_to_model_data(object) do
    Logger.debug("We're converting raw ActivityStream data to a comment entity")
    Logger.debug(inspect(object))

    tag_object = Map.get(object, "tag", [])

    case maybe_fetch_actor_and_attributed_to_id(object) do
      {:ok, %Actor{id: actor_id, domain: actor_domain}, attributed_to} ->
        data = %{
          text: object["content"],
          url: object["id"],
          # Will be used in conversations, ignored in basic comments
          title: object["name"],
          context: object["context"],
          actor_id: actor_id,
          attributed_to_id: if(is_nil(attributed_to), do: nil, else: attributed_to.id),
          in_reply_to_comment_id: nil,
          event_id: nil,
          uuid: object["uuid"],
          discussion_id: get_discussion_id(object),
          tags: fetch_tags(tag_object),
          mentions: fetch_mentions(tag_object),
          local: is_nil(actor_domain),
          visibility: if(Visibility.public?(object), do: :public, else: :private),
          published_at: object["published"],
          is_announcement: Map.get(object, "isAnnouncement", false)
        }

        maybe_fetch_parent_object(object, data)

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Make an AS comment object from an existing `Comment` structure.

  A "soft-deleted" comment is a tombstone
  """
  @impl Converter
  @spec model_to_as(CommentModel.t()) :: map
  def model_to_as(
        %CommentModel{
          deleted_at: nil,
          attributed_to: attributed_to,
          actor: %Actor{url: comment_actor_url}
        } = comment
      ) do
    to = determine_to(comment)

    attributed_to =
      if is_nil(attributed_to),
        do: comment_actor_url,
        else: Map.get(attributed_to, :url, comment_actor_url)

    object = %{
      "type" => "Note",
      "to" => to,
      "cc" => [],
      "content" => comment.text,
      "mediaType" => "text/html",
      "actor" => comment.actor.url,
      "attributedTo" => attributed_to,
      "uuid" => comment.uuid,
      "id" => comment.url,
      "tag" => build_mentions(comment.mentions) ++ build_tags(comment.tags),
      "published" => comment.published_at |> DateTime.to_iso8601(),
      "isAnnouncement" => comment.is_announcement
    }

    object =
      if comment.discussion_id,
        do: Map.put(object, "context", comment.discussion.url),
        else: object

    cond do
      comment.in_reply_to_comment ->
        Map.put(object, "inReplyTo", comment.in_reply_to_comment.url)

      comment.event ->
        Map.put(object, "inReplyTo", comment.event.url)

      true ->
        object
    end
  end

  @impl Converter
  def model_to_as(%CommentModel{} = comment) do
    Convertible.model_to_as(%TombstoneModel{
      uri: comment.url,
      actor: comment.actor,
      inserted_at: comment.deleted_at
    })
  end

  @spec determine_to(CommentModel.t()) :: [String.t()]
  defp determine_to(%CommentModel{visibility: :private, mentions: mentions} = _comment) do
    Enum.map(mentions, fn mention -> mention.actor.url end)
  end

  defp determine_to(%CommentModel{visibility: :public} = comment) do
    if is_nil(comment.attributed_to) do
      ["https://www.w3.org/ns/activitystreams#Public"]
    else
      [comment.attributed_to.url]
    end
  end

  defp determine_to(%CommentModel{} = comment) do
    [comment.actor.followers_url]
  end

  defp maybe_fetch_parent_object(object, data) do
    # We fetch the parent object
    Logger.debug("We're fetching the parent object")

    if Map.has_key?(object, "inReplyTo") && object["inReplyTo"] != nil &&
         object["inReplyTo"] != "" do
      Logger.debug(fn -> "Object has inReplyTo #{object["inReplyTo"]}" end)

      case ActivityPub.fetch_object_from_url(object["inReplyTo"]) do
        # Reply to an event (Event)
        {:ok, %Event{id: id} = event} ->
          Logger.debug("Parent object is an event")

          data
          |> Map.put(:event_id, id)
          |> Map.put(:event, event)

        # Reply to a comment (Comment)
        {:ok, %CommentModel{id: id} = comment} ->
          Logger.debug("Parent object is another comment")

          data
          |> Map.put(:in_reply_to_comment_id, id)
          |> Map.put(:origin_comment_id, comment |> CommentModel.get_thread_id())
          |> Map.put(:event_id, comment.event_id)
          |> Map.put(:conversation_id, comment.conversation_id)

        # Reply to a discucssion (Discussion)
        {:ok,
         %Discussion{
           id: discussion_id,
           last_comment: %CommentModel{id: last_comment_id, origin_comment_id: origin_comment_id}
         } = _discussion} ->
          Logger.debug("Parent object is a discussion")

          data
          |> Map.put(:in_reply_to_comment_id, last_comment_id)
          |> Map.put(:origin_comment_id, origin_comment_id)
          |> Map.put(:discussion_id, discussion_id)

        # Reply to a deleted entity
        {:ok, %Mobilizon.Tombstone{}} ->
          data

        # Anything else is kind of a MP
        {:error, parent} ->
          Logger.warning("Parent object is something we don't handle")
          Logger.debug(inspect(parent))
          data
      end
    else
      Logger.debug("No parent object for this comment")

      data
    end
  end

  defp get_discussion_id(%{"context" => context}) do
    case Discussions.get_discussion_by_url(context) do
      %Discussion{id: discussion_id} -> discussion_id
      nil -> nil
    end
  end

  defp get_discussion_id(_object), do: nil
end
