defmodule Mobilizon.Federation.ActivityStream.Converter.Conversation do
  @moduledoc """
  Comment converter.

  This module allows to convert conversations from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Conversation, as: ConversationConverter
  alias Mobilizon.Storage.Repo
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  require Logger

  @behaviour Converter

  defimpl Convertible, for: Conversation do
    defdelegate model_to_as(comment), to: ConversationConverter
  end

  @doc """
  Make an AS comment object from an existing `conversation` structure.
  """
  @impl Converter
  @spec model_to_as(Conversation.t()) :: map
  def model_to_as(%Conversation{} = conversation) do
    conversation = Repo.preload(conversation, [:participants, last_comment: [:actor]])

    %{
      "type" => "Note",
      "to" => Enum.map(conversation.participants, & &1.url),
      "cc" => [],
      "content" => conversation.last_comment.text,
      "mediaType" => "text/html",
      "actor" => conversation.last_comment.actor.url,
      "id" => conversation.last_comment.url,
      "publishedAt" => conversation.inserted_at
    }
  end

  @impl Converter
  @spec as_to_model_data(map) :: map() | {:error, atom()}
  def as_to_model_data(%{"type" => "Note", "name" => name} = object) when is_valid_string(name) do
    with %{actor_id: actor_id, creator_id: creator_id} <- extract_actors(object) do
      %{actor_id: actor_id, creator_id: creator_id, title: name, url: object["id"]}
    end
  end

  @spec extract_actors(map()) ::
          %{actor_id: String.t(), creator_id: String.t()} | {:error, atom()}
  defp extract_actors(%{"actor" => creator_url, "attributedTo" => actor_url} = _object)
       when is_valid_string(creator_url) and is_valid_string(actor_url) do
    with {:ok, %Actor{id: creator_id, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(creator_url),
         {:ok, %Actor{id: actor_id, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      %{actor_id: actor_id, creator_id: creator_id}
    else
      {:error, error} -> {:error, error}
      {:ok, %Actor{url: ^creator_url}} -> {:error, :creator_suspended}
      {:ok, %Actor{url: ^actor_url}} -> {:error, :actor_suspended}
    end
  end
end
