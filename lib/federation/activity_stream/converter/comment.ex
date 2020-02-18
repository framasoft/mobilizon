defmodule Mobilizon.Federation.ActivityStream.Converter.Comment do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment, as: CommentModel
  alias Mobilizon.Events.Event
  alias Mobilizon.Tombstone, as: TombstoneModel

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Visibility
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils

  require Logger

  @behaviour Converter

  defimpl Convertible, for: CommentModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Comment, as: CommentConverter

    defdelegate model_to_as(comment), to: CommentConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(object) do
    Logger.debug("We're converting raw ActivityStream data to a comment entity")
    Logger.debug(inspect(object))

    with author_url <- Map.get(object, "actor") || Map.get(object, "attributedTo"),
         {:ok, %Actor{id: actor_id, domain: domain}} <-
           ActivityPub.get_or_fetch_actor_by_url(author_url),
         {:tags, tags} <- {:tags, ConverterUtils.fetch_tags(Map.get(object, "tag", []))},
         {:mentions, mentions} <-
           {:mentions, ConverterUtils.fetch_mentions(Map.get(object, "tag", []))} do
      Logger.debug("Inserting full comment")
      Logger.debug(inspect(object))

      data = %{
        text: object["content"],
        url: object["id"],
        actor_id: actor_id,
        in_reply_to_comment_id: nil,
        event_id: nil,
        uuid: object["uuid"],
        tags: tags,
        mentions: mentions,
        local: is_nil(domain),
        visibility: if(Visibility.is_public?(object), do: :public, else: :private)
      }

      # We fetch the parent object
      Logger.debug("We're fetching the parent object")

      if Map.has_key?(object, "inReplyTo") && object["inReplyTo"] != nil &&
           object["inReplyTo"] != "" do
        Logger.debug(fn -> "Object has inReplyTo #{object["inReplyTo"]}" end)

        case ActivityPub.fetch_object_from_url(object["inReplyTo"]) do
          # Reply to an event (Event)
          {:ok, %Event{id: id}} ->
            Logger.debug("Parent object is an event")
            data |> Map.put(:event_id, id)

          # Reply to a comment (Comment)
          {:ok, %CommentModel{id: id} = comment} ->
            Logger.debug("Parent object is another comment")

            data
            |> Map.put(:in_reply_to_comment_id, id)
            |> Map.put(:origin_comment_id, comment |> CommentModel.get_thread_id())
            |> Map.put(:event_id, comment.event_id)

          # Anything else is kind of a MP
          {:error, parent} ->
            Logger.warn("Parent object is something we don't handle")
            Logger.debug(inspect(parent))
            data
        end
      else
        Logger.debug("No parent object for this comment")

        data
      end
    end
  end

  @doc """
  Make an AS comment object from an existing `Comment` structure.
  """
  @impl Converter
  @spec model_to_as(CommentModel.t()) :: map
  def model_to_as(%CommentModel{deleted_at: nil} = comment) do
    to =
      if comment.visibility == :public,
        do: ["https://www.w3.org/ns/activitystreams#Public"],
        else: [comment.actor.followers_url]

    object = %{
      "type" => "Note",
      "to" => to,
      "cc" => [],
      "content" => comment.text,
      "mediaType" => "text/html",
      "actor" => comment.actor.url,
      "attributedTo" => comment.actor.url,
      "uuid" => comment.uuid,
      "id" => comment.url,
      "tag" =>
        ConverterUtils.build_mentions(comment.mentions) ++ ConverterUtils.build_tags(comment.tags)
    }

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
  @spec model_to_as(CommentModel.t()) :: map
  @doc """
  A "soft-deleted" comment is a tombstone
  """
  def model_to_as(%CommentModel{} = comment) do
    Convertible.model_to_as(%TombstoneModel{
      uri: comment.url,
      inserted_at: comment.deleted_at
    })
  end
end
