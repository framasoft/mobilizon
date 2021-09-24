defmodule Mobilizon.Federation.ActivityPub.Types.Comments do
  @moduledoc false
  alias Mobilizon.{Actors, Discussions, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.Federation.ActivityPub.{Audience, Permission}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Comment, as: CommentActivity
  alias Mobilizon.Service.LanguageDetection
  alias Mobilizon.Share
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Comment.t(), ActivityStream.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :event_not_allow_commenting}
  def create(args, additional) do
    args = prepare_args_for_comment(args)

    if event_allows_commenting?(args) do
      case Discussions.create_comment(args) do
        {:ok, %Comment{discussion_id: discussion_id} = comment} ->
          CommentActivity.insert_activity(comment,
            subject: "comment_posted"
          )

          maybe_publish_graphql_subscription(discussion_id)
          comment_as_data = Convertible.model_to_as(comment)
          audience = Audience.get_audience(comment)
          create_data = make_create_data(comment_as_data, Map.merge(audience, additional))
          {:ok, comment, create_data}

        {:error, %Ecto.Changeset{} = err} ->
          {:error, err}
      end
    else
      {:error, :event_not_allow_commenting}
    end
  end

  @impl Entity
  @spec update(Comment.t(), map(), map()) ::
          {:ok, Comment.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def update(%Comment{} = old_comment, args, additional) do
    args = prepare_args_for_comment_update(args)

    case Discussions.update_comment(old_comment, args) do
      {:ok, %Comment{} = new_comment} ->
        {:ok, true} = Cachex.del(:activity_pub, "comment_#{new_comment.uuid}")
        comment_as_data = Convertible.model_to_as(new_comment)
        audience = Audience.get_audience(new_comment)
        update_data = make_update_data(comment_as_data, Map.merge(audience, additional))
        {:ok, new_comment, update_data}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec delete(Comment.t(), Actor.t(), boolean, map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Comment.t()} | {:error, Ecto.Changeset.t()}
  def delete(
        %Comment{url: url, id: comment_id},
        %Actor{} = actor,
        _local,
        options \\ %{}
      ) do
    comment = Discussions.get_comment_with_preload(comment_id)

    activity_data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => Convertible.model_to_as(comment),
      "id" => url <> "/delete",
      "to" => ["https://www.w3.org/ns/activitystreams#Public"]
    }

    force_deletion = Map.get(options, :force, false)

    audience = Audience.get_audience(comment)

    case Discussions.delete_comment(comment, force: force_deletion) do
      {:ok, %Comment{} = updated_comment} ->
        Cachex.del(:activity_pub, "comment_#{comment.uuid}")
        Tombstone.create_tombstone(%{uri: comment.url, actor_id: actor.id})
        Share.delete_all_by_uri(comment.url)
        {:ok, Map.merge(activity_data, audience), actor, updated_comment}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(Comment.t()) :: Actor.t() | nil
  def actor(%Comment{actor: %Actor{} = actor}), do: actor

  def actor(%Comment{actor_id: actor_id}) when not is_nil(actor_id),
    do: Actors.get_actor(actor_id)

  def actor(_), do: nil

  @spec group_actor(Comment.t()) :: Actor.t() | nil
  def group_actor(%Comment{attributed_to: %Actor{} = group}), do: group

  def group_actor(%Comment{attributed_to_id: attributed_to_id}) when not is_nil(attributed_to_id),
    do: Actors.get_actor(attributed_to_id)

  def group_actor(_), do: nil

  @spec permissions(Comment.t()) :: Permission.t()
  def permissions(%Comment{}),
    do: %Permission{
      access: :member,
      create: :member,
      update: :administrator,
      delete: :administrator
    }

  # Prepare and sanitize arguments for comments
  @spec prepare_args_for_comment(map) :: map
  defp prepare_args_for_comment(args) do
    with in_reply_to_comment <-
           args |> Map.get(:in_reply_to_comment_id) |> Discussions.get_comment_with_preload(),
         event <- args |> Map.get(:event_id) |> handle_event_for_comment(),
         args <- Map.update(args, :visibility, :public, & &1),
         {text, mentions, tags} <-
           APIUtils.make_content_html(
             args |> Map.get(:text, "") |> String.trim(),
             # Can't put additional tags on a comment
             [],
             "text/html"
           ),
         tags <- ConverterUtils.fetch_tags(tags),
         mentions <- Map.get(args, :mentions, []) ++ ConverterUtils.fetch_mentions(mentions),
         lang <- Map.get(args, :language, "und"),
         args <-
           Map.merge(args, %{
             actor_id: Map.get(args, :actor_id),
             text: text,
             mentions: mentions,
             tags: tags,
             event: event,
             in_reply_to_comment: in_reply_to_comment,
             in_reply_to_comment_id:
               if(is_nil(in_reply_to_comment), do: nil, else: Map.get(in_reply_to_comment, :id)),
             origin_comment_id:
               if(is_nil(in_reply_to_comment),
                 do: nil,
                 else: Comment.get_thread_id(in_reply_to_comment)
               ),
             language: if(lang == "und", do: LanguageDetection.detect(:comment, args), else: lang)
           }) do
      args
    end
  end

  @spec prepare_args_for_comment_update(map) :: map
  defp prepare_args_for_comment_update(args) do
    with {text, mentions, tags} <-
           APIUtils.make_content_html(
             args |> Map.get(:text, "") |> String.trim(),
             # Can't put additional tags on a comment
             [],
             "text/html"
           ),
         tags <- ConverterUtils.fetch_tags(tags),
         mentions <- Map.get(args, :mentions, []) ++ ConverterUtils.fetch_mentions(mentions) do
      Map.merge(args, %{text: text, mentions: mentions, tags: tags})
    end
  end

  @spec handle_event_for_comment(String.t() | integer() | nil) :: Event.t() | nil
  defp handle_event_for_comment(event_id) when not is_nil(event_id) do
    case Events.get_event_with_preload(event_id) do
      {:ok, %Event{} = event} -> event
      {:error, :event_not_found} -> nil
    end
  end

  defp handle_event_for_comment(nil), do: nil

  @spec maybe_publish_graphql_subscription(String.t() | integer() | nil) :: :ok
  defp maybe_publish_graphql_subscription(nil), do: :ok

  defp maybe_publish_graphql_subscription(discussion_id) do
    case Discussions.get_discussion(discussion_id) do
      %Discussion{} = discussion ->
        Absinthe.Subscription.publish(Endpoint, discussion,
          discussion_comment_changed: discussion.slug
        )

        :ok

      nil ->
        :ok
    end
  end

  @spec event_allows_commenting?(%{actor_id: String.t() | integer, event: Event.t()}) :: boolean
  defp event_allows_commenting?(%{
         actor_id: actor_id,
         event: %Event{
           options: %EventOptions{comment_moderation: comment_moderation},
           organizer_actor_id: organizer_actor_id
         }
       }) do
    comment_moderation != :closed ||
      to_string(actor_id) == to_string(organizer_actor_id)
  end

  # Comments not attached to events
  defp event_allows_commenting?(_), do: true
end
