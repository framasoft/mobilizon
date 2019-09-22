defmodule Mobilizon.Service.ActivityPub.Converters.Comment do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Comment, as: CommentModel
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Converter

  require Logger

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map()
  def as_to_model_data(object) do
    {:ok, %Actor{id: actor_id}} = ActivityPub.get_or_fetch_by_url(object["actor"])
    Logger.debug("Inserting full comment")
    Logger.debug(inspect(object))

    data = %{
      "text" => object["content"],
      "url" => object["id"],
      "actor_id" => actor_id,
      "in_reply_to_comment_id" => nil,
      "event_id" => nil,
      "uuid" => object["uuid"]
    }

    # We fetch the parent object
    Logger.debug("We're fetching the parent object")

    data =
      if Map.has_key?(object, "inReplyTo") && object["inReplyTo"] != nil &&
           object["inReplyTo"] != "" do
        Logger.debug(fn -> "Object has inReplyTo #{object["inReplyTo"]}" end)

        case ActivityPub.fetch_object_from_url(object["inReplyTo"]) do
          # Reply to an event (Event)
          {:ok, %Event{id: id}} ->
            Logger.debug("Parent object is an event")
            data |> Map.put("event_id", id)

          # Reply to a comment (Comment)
          {:ok, %CommentModel{id: id} = comment} ->
            Logger.debug("Parent object is another comment")

            data
            |> Map.put("in_reply_to_comment_id", id)
            |> Map.put("origin_comment_id", comment |> CommentModel.get_thread_id())

          # Anything else is kind of a MP
          {:error, parent} ->
            Logger.debug("Parent object is something we don't handle")
            Logger.debug(inspect(parent))
            data
        end
      else
        Logger.debug("No parent object for this comment")
        data
      end

    data
  end

  @doc """
  Make an AS comment object from an existing `Comment` structure.
  """
  @impl Converter
  @spec model_to_as(CommentModel.t()) :: map()
  def model_to_as(%CommentModel{} = comment) do
    object = %{
      "type" => "Note",
      "to" => ["https://www.w3.org/ns/activitystreams#Public"],
      "content" => comment.text,
      "actor" => comment.actor.url,
      "attributedTo" => comment.actor.url,
      "uuid" => comment.uuid,
      "id" => comment.url
    }

    if comment.in_reply_to_comment do
      object |> Map.put("inReplyTo", comment.in_reply_to_comment.url || comment.event.url)
    else
      object
    end
  end
end

defimpl Mobilizon.Service.ActivityPub.Convertible, for: Mobilizon.Events.Comment do
  alias Mobilizon.Service.ActivityPub.Converters.Comment, as: CommentConverter

  defdelegate model_to_as(comment), to: CommentConverter
end
