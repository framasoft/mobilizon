defmodule Mobilizon.Federation.ActivityPub.Types.Posts do
  @moduledoc false
  alias Mobilizon.{Actors, Posts, Tombstone}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Posts.Post
  require Logger
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]

  @behaviour Entity

  @public_ap "https://www.w3.org/ns/activitystreams#Public"

  @impl Entity
  def create(args, additional) do
    with args <- Map.update(args, :tags, [], &ConverterUtils.fetch_tags/1),
         {:ok, %Post{attributed_to_id: group_id, author_id: creator_id} = post} <-
           Posts.create_post(args),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} = creator <- Actors.get_actor(creator_id),
         post_as_data <-
           Convertible.model_to_as(%{post | attributed_to: group, author: creator}),
         audience <- %{
           "to" => [group.members_url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         } do
      create_data = make_create_data(post_as_data, Map.merge(audience, additional))

      {:ok, post, create_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  def update(%Post{} = post, args, additional) do
    with args <- Map.update(args, :tags, [], &ConverterUtils.fetch_tags/1),
         {:ok, %Post{attributed_to_id: group_id, author_id: creator_id} = post} <-
           Posts.update_post(post, args),
         {:ok, true} <- Cachex.del(:activity_pub, "post_#{post.slug}"),
         {:ok, %Actor{url: group_url} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} = creator <- Actors.get_actor(creator_id),
         post_as_data <-
           Convertible.model_to_as(%{post | attributed_to: group, author: creator}),
         audience <- %{
           "to" => [group.members_url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [group_url]
         } do
      update_data = make_update_data(post_as_data, Map.merge(audience, additional))

      {:ok, post, update_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
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
      "object" => Convertible.model_to_as(post),
      "id" => url <> "/delete",
      "to" => [group_url, @public_ap, members_url]
    }

    with {:ok, %Post{} = post} <- Posts.delete_post(post),
         {:ok, true} <- Cachex.del(:activity_pub, "post_#{post.slug}"),
         {:ok, %Tombstone{} = _tombstone} <-
           Tombstone.create_tombstone(%{uri: post.url, actor_id: actor.id}) do
      {:ok, activity_data, actor, post}
    end
  end

  def actor(%Post{author_id: author_id}),
    do: Actors.get_actor(author_id)

  def group_actor(%Post{attributed_to_id: attributed_to_id}),
    do: Actors.get_actor(attributed_to_id)

  def role_needed_to_update(%Post{}), do: :moderator
  def role_needed_to_delete(%Post{}), do: :moderator
end
