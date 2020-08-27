defmodule Mobilizon.Federation.ActivityStream.Converter.Discussion do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Discussion, as: DiscussionConverter
  alias Mobilizon.Storage.Repo

  require Logger

  @behaviour Converter

  defimpl Convertible, for: Discussion do
    defdelegate model_to_as(comment), to: DiscussionConverter
  end

  @doc """
  Make an AS comment object from an existing `discussion` structure.
  """
  @impl Converter
  @spec model_to_as(Discussion.t()) :: map
  def model_to_as(%Discussion{} = discussion) do
    discussion = Repo.preload(discussion, [:last_comment, :actor, :creator])

    %{
      "type" => "Note",
      "to" => [discussion.actor.followers_url],
      "cc" => [],
      "name" => discussion.title,
      "content" => discussion.last_comment.text,
      "mediaType" => "text/html",
      "actor" => discussion.creator.url,
      "attributedTo" => discussion.actor.url,
      "id" => discussion.url,
      "publishedAt" => discussion.inserted_at,
      "context" => discussion.url
    }
  end

  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(%{"type" => "Note", "name" => name} = object) when not is_nil(name) do
    with creator_url <- Map.get(object, "actor"),
         {:ok, %Actor{id: creator_id, suspended: false}} <-
           ActivityPub.get_or_fetch_actor_by_url(creator_url),
         actor_url <- Map.get(object, "attributedTo"),
         {:ok, %Actor{id: actor_id, suspended: false}} <-
           ActivityPub.get_or_fetch_actor_by_url(actor_url) do
      %{
        title: name,
        actor_id: actor_id,
        creator_id: creator_id,
        url: object["id"]
      }
    end
  end
end
