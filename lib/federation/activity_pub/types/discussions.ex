defmodule Mobilizon.Federation.ActivityPub.Types.Discussions do
  @moduledoc false

  alias Mobilizon.{Actors, Discussions}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Discussion, as: DiscussionActivity
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(%{discussion_id: discussion_id} = args, additional) when not is_nil(discussion_id) do
    with args <- prepare_args(args),
         %Discussion{} = discussion <- Discussions.get_discussion(discussion_id),
         {:ok, %Discussion{last_comment_id: last_comment_id} = discussion} <-
           Discussions.reply_to_discussion(discussion, args),
         {:ok, _} <-
           DiscussionActivity.insert_activity(discussion,
             subject: "discussion_replied",
             actor_id: Map.get(args, :creator_id, args.actor_id)
           ),
         %Comment{} = last_comment <- Discussions.get_comment_with_preload(last_comment_id),
         :ok <- maybe_publish_graphql_subscription(discussion),
         comment_as_data <- Convertible.model_to_as(last_comment),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(discussion),
         create_data <-
           make_create_data(comment_as_data, Map.merge(audience, additional)) do
      {:ok, discussion, create_data}
    end
  end

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(args, additional) do
    with args <- prepare_args(args),
         {:ok, %Discussion{} = discussion} <-
           Discussions.create_discussion(args),
         {:ok, _} <-
           DiscussionActivity.insert_activity(discussion, subject: "discussion_created"),
         discussion_as_data <- Convertible.model_to_as(discussion),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(discussion),
         create_data <-
           make_create_data(discussion_as_data, Map.merge(audience, additional)) do
      {:ok, discussion, create_data}
    end
  end

  @impl Entity
  @spec update(Discussion.t(), map(), map()) :: {:ok, Discussion.t(), Activity.t()} | any()
  def update(%Discussion{} = old_discussion, args, additional) do
    with {:ok, %Discussion{} = new_discussion} <-
           Discussions.update_discussion(old_discussion, args),
         {:ok, _} <-
           DiscussionActivity.insert_activity(new_discussion,
             subject: "discussion_renamed",
             old_discussion: old_discussion
           ),
         {:ok, true} <- Cachex.del(:activity_pub, "discussion_#{new_discussion.slug}"),
         discussion_as_data <- Convertible.model_to_as(new_discussion),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_discussion),
         update_data <- make_update_data(discussion_as_data, Map.merge(audience, additional)) do
      {:ok, new_discussion, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  @spec delete(Discussion.t(), Actor.t(), boolean, map()) :: {:ok, Discussion.t()}
  def delete(
        %Discussion{actor: group, url: url} = discussion,
        %Actor{} = actor,
        _local,
        _additionnal
      ) do
    with {:ok, _} <- Discussions.delete_discussion(discussion),
         {:ok, _} <-
           DiscussionActivity.insert_activity(discussion,
             subject: "discussion_deleted",
             moderator: actor
           ) do
      # This is just fake
      activity_data = %{
        "type" => "Delete",
        "actor" => actor.url,
        "object" => Convertible.model_to_as(discussion),
        "id" => url <> "/delete",
        "to" => [group.members_url]
      }

      {:ok, activity_data, actor, discussion}
    end
  end

  def actor(%Discussion{creator_id: creator_id}), do: Actors.get_actor(creator_id)

  def group_actor(%Discussion{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  def role_needed_to_update(%Discussion{}), do: :moderator
  def role_needed_to_delete(%Discussion{}), do: :moderator

  @spec maybe_publish_graphql_subscription(Discussion.t()) :: :ok
  defp maybe_publish_graphql_subscription(%Discussion{} = discussion) do
    Absinthe.Subscription.publish(Endpoint, discussion,
      discussion_comment_changed: discussion.slug
    )

    :ok
  end

  defp prepare_args(args) do
    {text, _mentions, _tags} =
      APIUtils.make_content_html(
        args |> Map.get(:text, "") |> String.trim(),
        # Can't put additional tags on a comment
        [],
        "text/html"
      )

    args
    # title might be nil
    |> Map.update(:title, "", fn title -> String.trim(title || "") end)
    |> Map.put(:text, text)
  end
end
