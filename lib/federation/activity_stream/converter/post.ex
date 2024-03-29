defmodule Mobilizon.Federation.ActivityStream.Converter.Post do
  @moduledoc """
  Post converter.

  This module allows to convert posts from ActivityStream format to our own
  internal one, and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.{Audience, Utils}
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Media, as: MediaConverter
  alias Mobilizon.Posts.Post
  require Logger

  import Mobilizon.Federation.ActivityStream.Converter.Utils,
    only: [
      process_pictures: 2,
      visibility_public?: 1
    ]

  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  @behaviour Converter

  defimpl Convertible, for: Post do
    alias Mobilizon.Federation.ActivityStream.Converter.Post, as: PostConverter

    defdelegate model_to_as(post), to: PostConverter
  end

  @banner_picture_name "Banner"

  @doc """
  Convert an post struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(Post.t()) :: map
  def model_to_as(
        %Post{
          author: %Actor{url: actor_url},
          attributed_to: %Actor{
            url: creator_url
          }
        } = post
      ) do
    audience = Audience.get_audience(post)

    %{
      "type" => "Article",
      "actor" => actor_url,
      "id" => post.url,
      "name" => post.title,
      "content" => post.body,
      "attributedTo" => creator_url,
      "published" => (post.publish_at || post.inserted_at) |> to_date(),
      "attachment" => [],
      "draft" => post.draft
    }
    |> Map.merge(audience)
    |> maybe_add_post_picture(post)
    |> maybe_add_inline_media(post)
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map() | {:error, any()}
  def as_to_model_data(
        %{"type" => "Article", "actor" => creator, "attributedTo" => group_uri} = object
      ) do
    with {:ok, %Actor{id: attributed_to_id} = group} <- get_actor(group_uri),
         {:ok, %Actor{id: author_id}} <- get_actor(creator) do
      [description: description, picture_id: picture_id, medias: medias] =
        process_pictures(object, attributed_to_id)

      %{
        title: object["name"],
        body: description,
        url: object["id"],
        attributed_to_id: attributed_to_id,
        author_id: author_id,
        local: false,
        publish_at: object["published"],
        picture_id: picture_id,
        medias: medias,
        visibility: get_visibility(object, group),
        draft: object["draft"] == true
      }
    else
      {:error, err} -> {:error, err}
      err -> {:error, err}
    end
  end

  @spec get_actor(String.t() | map() | nil) :: {:ok, Actor.t()} | {:error, String.t()}
  defp get_actor(actor) when is_valid_string(actor),
    do: actor |> Utils.get_url() |> ActivityPubActor.get_or_fetch_actor_by_url()

  defp get_actor(_), do: {:error, "nil property found for actor data"}

  @spec to_date(DateTime.t() | NaiveDateTime.t() | nil) :: String.t() | nil
  defp to_date(nil), do: nil
  defp to_date(%DateTime{} = date), do: DateTime.to_iso8601(date)
  defp to_date(%NaiveDateTime{} = date), do: NaiveDateTime.to_iso8601(date)

  @spec maybe_add_post_picture(map(), Post.t()) :: map()
  defp maybe_add_post_picture(res, post) do
    if is_nil(post.picture),
      do: res,
      else:
        Map.update(
          res,
          "attachment",
          [],
          &(&1 ++
              [
                post.picture
                |> MediaConverter.model_to_as()
                |> Map.put("name", @banner_picture_name)
              ])
        )
  end

  @spec maybe_add_inline_media(map(), Post.t()) :: map()
  defp maybe_add_inline_media(res, post) do
    medias = Enum.map(post.media, &MediaConverter.model_to_as/1)

    Map.update(
      res,
      "attachment",
      [],
      &(&1 ++ medias)
    )
  end

  defp get_visibility(%{"to" => to}, %Actor{
         followers_url: followers_url,
         members_url: members_url
       }) do
    cond do
      visibility_public?(to) -> :public
      followers_url in to -> :unlisted
      members_url in to -> :private
    end
  end
end
