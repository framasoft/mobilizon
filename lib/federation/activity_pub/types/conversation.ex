defmodule Mobilizon.Federation.ActivityPub.Types.Conversations do
  @moduledoc false

  # alias Mobilizon.Conversations.ConversationParticipant
  alias Mobilizon.{Actors, Conversations, Discussions}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.{Audience, Permission}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Conversation, as: ConversationActivity
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Conversation.t(), ActivityStream.t()}
          | {:error,
             :conversation_not_found
             | :last_comment_not_found
             | :empty_participants
             | Ecto.Changeset.t()}
  def create(%{conversation_id: conversation_id} = args, additional)
      when not is_nil(conversation_id) do
    Logger.debug("Creating a reply to a conversation #{inspect(args, pretty: true)}")
    args = prepare_args(args)
    Logger.debug("Creating a reply to a conversation #{inspect(args, pretty: true)}")

    with args when is_map(args) <- prepare_args(args) do
      case Conversations.get_conversation(conversation_id) do
        %Conversation{} = conversation ->
          case Conversations.reply_to_conversation(conversation, args) do
            {:ok, %Conversation{last_comment_id: last_comment_id} = conversation} ->
              ConversationActivity.insert_activity(conversation, subject: "conversation_replied")
              maybe_publish_graphql_subscription(conversation)

              case Discussions.get_comment_with_preload(last_comment_id) do
                %Comment{} = last_comment ->
                  comment_as_data = Convertible.model_to_as(last_comment)
                  audience = Audience.get_audience(conversation)
                  create_data = make_create_data(comment_as_data, Map.merge(audience, additional))
                  {:ok, conversation, create_data}

                nil ->
                  {:error, :last_comment_not_found}
              end

            {:error, _, %Ecto.Changeset{} = err, _} ->
              {:error, err}
          end

        nil ->
          {:error, :discussion_not_found}
      end
    end
  end

  @impl Entity
  def create(args, additional) do
    with args when is_map(args) <- prepare_args(args) do
      case Conversations.create_conversation(args) do
        {:ok, %Conversation{} = conversation} ->
          ConversationActivity.insert_activity(conversation, subject: "conversation_created")
          conversation_as_data = Convertible.model_to_as(conversation)
          audience = Audience.get_audience(conversation)
          create_data = make_create_data(conversation_as_data, Map.merge(audience, additional))
          {:ok, conversation, create_data}

        {:error, _, %Ecto.Changeset{} = err, _} ->
          {:error, err}
      end
    end
  end

  @impl Entity
  @spec update(Conversation.t(), map(), map()) ::
          {:ok, Conversation.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def update(%Conversation{} = old_conversation, args, additional) do
    case Conversations.update_conversation(old_conversation, args) do
      {:ok, %Conversation{} = new_conversation} ->
        # ConversationActivity.insert_activity(new_conversation,
        #   subject: "conversation_renamed",
        #   old_conversation: old_conversation
        # )

        conversation_as_data = Convertible.model_to_as(new_conversation)
        audience = Audience.get_audience(new_conversation)
        update_data = make_update_data(conversation_as_data, Map.merge(audience, additional))
        {:ok, new_conversation, update_data}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec delete(Conversation.t(), Actor.t(), boolean, map()) ::
          {:error, Ecto.Changeset.t()} | {:ok, ActivityStream.t(), Actor.t(), Conversation.t()}
  def delete(
        %Conversation{} = _conversation,
        %Actor{} = _actor,
        _local,
        _additionnal
      ) do
    {:error, :not_applicable}
  end

  # @spec actor(Conversation.t()) :: Actor.t() | nil
  # def actor(%ConversationParticipant{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  # @spec group_actor(Conversation.t()) :: Actor.t() | nil
  # def group_actor(%Conversation{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  @spec permissions(Conversation.t()) :: Permission.t()
  def permissions(%Conversation{}) do
    %Permission{access: :member, create: :member, update: :moderator, delete: :moderator}
  end

  @spec maybe_publish_graphql_subscription(Conversation.t()) :: :ok
  defp maybe_publish_graphql_subscription(%Conversation{} = conversation) do
    Absinthe.Subscription.publish(Endpoint, conversation,
      conversation_comment_changed: conversation.id
    )

    :ok
  end

  @spec prepare_args(map) :: map | {:error, :empty_participants}
  defp prepare_args(args) do
    {text, mentions, _tags} =
      APIUtils.make_content_html(
        args |> Map.get(:text, "") |> String.trim(),
        # Can't put additional tags on a comment
        [],
        "text/html"
      )

    mentions =
      (args |> Map.get(:mentions, []) |> prepare_mentions()) ++
        ConverterUtils.fetch_mentions(mentions)

    if Enum.empty?(mentions) do
      {:error, :empty_participants}
    else
      event = Map.get(args, :event, get_event(Map.get(args, :event_id)))

      participants =
        (mentions ++
           [
             %{actor_id: args.actor_id},
             %{
               actor_id:
                 if(is_nil(event),
                   do: nil,
                   else: event.attributed_to_id || event.organizer_actor_id
                 )
             }
           ])
        |> Enum.reduce(
          [],
          fn %{actor_id: actor_id}, acc ->
            case Actors.get_actor(actor_id) do
              nil -> acc
              actor -> acc ++ [actor]
            end
          end
        )
        |> Enum.uniq_by(& &1.id)

      args
      |> Map.put(:text, text)
      |> Map.put(:mentions, mentions)
      |> Map.put(:participants, participants)
    end
  end

  @spec prepare_mentions(list(String.t())) :: list(%{actor_id: String.t()})
  defp prepare_mentions(mentions) do
    Enum.reduce(mentions, [], &prepare_mention/2)
  end

  @spec prepare_mention(String.t() | map(), list()) :: list(%{actor_id: String.t()})
  defp prepare_mention(%{actor_id: _} = mention, mentions) do
    mentions ++ [mention]
  end

  defp prepare_mention(mention, mentions) do
    case ActivityPubActor.find_or_make_actor_from_nickname(mention) do
      {:ok, %Actor{id: actor_id}} ->
        mentions ++ [%{actor_id: actor_id}]

      {:error, _} ->
        mentions
    end
  end

  defp get_event(nil), do: nil

  defp get_event(event_id) do
    case Mobilizon.Events.get_event(event_id) do
      {:ok, event} -> event
      _ -> nil
    end
  end
end
