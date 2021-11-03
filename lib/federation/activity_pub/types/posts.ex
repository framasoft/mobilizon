defmodule Mobilizon.Federation.ActivityPub.Types.Posts do
  @moduledoc false
  alias Mobilizon.{Actors, Posts, Tombstone}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.{Audience, Permission}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Activity.Post, as: PostsActivity
  alias Mobilizon.Service.LanguageDetection
  require Logger
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]

  @behaviour Entity

  @public_ap "https://www.w3.org/ns/activitystreams#Public"

  @impl Entity
  @spec create(map(), map()) :: {:ok, Post.t(), ActivityStream.t()}
  def create(args, additional) do
    with args <- prepare_args(args),
         {:ok, %Post{attributed_to_id: group_id, author_id: creator_id} = post} <-
           Posts.create_post(args),
         {:ok, _} <- PostsActivity.insert_activity(post, subject: "post_created"),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{} = creator <- Actors.get_actor(creator_id),
         post_as_data <-
           Convertible.model_to_as(%{post | attributed_to: group, author: creator}) do
      create_data = make_create_data(post_as_data, additional)

      {:ok, post, create_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  @spec update(Post.t(), map(), map()) :: {:ok, Post.t(), ActivityStream.t()}
  def update(%Post{} = post, args, additional) do
    with args <- prepare_args(args),
         {:ok, %Post{attributed_to_id: group_id, author_id: creator_id} = post} <-
           Posts.update_post(post, args),
         {:ok, _} <- PostsActivity.insert_activity(post, subject: "post_updated"),
         {:ok, true} <- Cachex.del(:activity_pub, "post_#{post.slug}"),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{} = creator <- Actors.get_actor(creator_id),
         post_as_data <-
           Convertible.model_to_as(%{post | attributed_to: group, author: creator}),
         audience <-
           Audience.get_audience(post) do
      update_data = make_update_data(post_as_data, Map.merge(audience, additional))

      {:ok, post, update_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  @spec delete(Post.t(), Actor.t(), boolean, map) ::
          {:ok, ActivityStream.t(), Actor.t(), Post.t()}
  def delete(
        %Post{
          url: url,
          attributed_to: %Actor{url: group_url, members_url: members_url}
        } = post,
        %Actor{url: actor_url} = actor,
        _local,
        _additionnal
      ) do
    activity_data = %{
      "actor" => actor_url,
      "type" => "Delete",
      "object" => %{
        "type" => "Tombstone",
        "id" => url
      },
      "id" => url <> "/delete",
      "to" => [group_url, @public_ap, members_url]
    }

    with {:ok, %Post{} = post} <- Posts.delete_post(post),
         {:ok, _} <- PostsActivity.insert_activity(post, subject: "post_deleted"),
         {:ok, true} <- Cachex.del(:activity_pub, "post_#{post.slug}"),
         {:ok, %Tombstone{} = _tombstone} <-
           Tombstone.create_tombstone(%{uri: post.url, actor_id: actor.id}) do
      {:ok, activity_data, actor, post}
    end
  end

  @spec actor(Post.t()) :: Actor.t() | nil
  def actor(%Post{author_id: author_id}),
    do: Actors.get_actor(author_id)

  @spec group_actor(Post.t()) :: Actor.t() | nil
  def group_actor(%Post{attributed_to_id: attributed_to_id}),
    do: Actors.get_actor(attributed_to_id)

  @spec permissions(Post.t()) :: Permission.t()
  def permissions(%Post{}) do
    %Permission{
      access: :member,
      create: :moderator,
      update: :moderator,
      delete: :moderator
    }
  end

  @spec prepare_args(map()) :: map
  defp prepare_args(args) do
    args
    |> Map.update(:tags, [], &ConverterUtils.fetch_tags/1)
    |> Map.put_new(:language, "und")
    |> Map.update!(:language, fn lang ->
      if lang == "und", do: LanguageDetection.detect(:post, args), else: lang
    end)
  end
end
