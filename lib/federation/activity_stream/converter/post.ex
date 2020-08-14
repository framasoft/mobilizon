defmodule Mobilizon.Federation.ActivityStream.Converter.Post do
  @moduledoc """
  Post converter.

  This module allows to convert posts from ActivityStream format to our own
  internal one, and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Posts.Post
  require Logger

  @behaviour Converter

  defimpl Convertible, for: Post do
    alias Mobilizon.Federation.ActivityStream.Converter.Post, as: PostConverter

    defdelegate model_to_as(post), to: PostConverter
  end

  @doc """
  Convert an post struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(Post.t()) :: map
  def model_to_as(
        %Post{author: %Actor{url: actor_url}, attributed_to: %Actor{url: creator_url}} = post
      ) do
    %{
      "type" => "Article",
      "actor" => actor_url,
      "id" => post.url,
      "name" => post.title,
      "content" => post.body,
      "attributedTo" => creator_url,
      "published" => (post.publish_at || post.inserted_at) |> DateTime.to_iso8601()
    }
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(
        %{"type" => "Article", "actor" => creator, "attributedTo" => group} = object
      ) do
    with {:ok, %Actor{id: attributed_to_id}} <- get_actor(group),
         {:ok, %Actor{id: author_id}} <- get_actor(creator) do
      %{
        title: object["name"],
        body: object["content"],
        url: object["id"],
        attributed_to_id: attributed_to_id,
        author_id: author_id,
        local: false,
        publish_at: object["published"]
      }
    else
      {:error, err} -> {:error, err}
      err -> {:error, err}
    end
  end

  @spec get_actor(String.t() | map() | nil) :: {:ok, Actor.t()} | {:error, String.t()}
  defp get_actor(nil), do: {:error, "nil property found for actor data"}
  defp get_actor(actor), do: actor |> Utils.get_url() |> ActivityPub.get_or_fetch_actor_by_url()
end
