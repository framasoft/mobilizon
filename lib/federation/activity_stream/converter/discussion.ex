defmodule Mobilizon.Federation.ActivityStream.Converter.Discussion do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Discussion, as: DiscussionConverter
  alias Mobilizon.Storage.Repo
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

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
      "to" => [discussion.actor.members_url],
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
  @spec as_to_model_data(map) :: map() | {:error, any()}
  def as_to_model_data(%{"type" => "Note", "name" => name} = object) when is_valid_string(name) do
    case extract_actors(object) do
      %{actor_id: actor_id, creator_id: creator_id} ->
        %{actor_id: actor_id, creator_id: creator_id, title: name, url: object["id"]}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec extract_actors(map()) :: %{actor_id: String.t(), creator_id: String.t()} | {:error, any()}
  defp extract_actors(%{"actor" => creator_url, "attributedTo" => actor_url} = _object)
       when is_valid_string(creator_url) and is_valid_string(actor_url) do
    with {:ok, %Actor{id: creator_id, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(creator_url),
         {:ok, %Actor{id: actor_id, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      %{actor_id: actor_id, creator_id: creator_id}
    else
      {:error, error} -> {:error, error}
    end
  end
end
