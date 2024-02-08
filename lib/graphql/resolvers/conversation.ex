defmodule Mobilizon.GraphQL.Resolvers.Conversation do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Conversations}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant, ConversationView}
  alias Mobilizon.Events.Event
  alias Mobilizon.GraphQL.API.Comments
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Web.Gettext, only: [dgettext: 2]
  require Logger

  @spec find_conversations_for_event(Event.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(ConversationView.t())} | {:error, :unauthenticated}
  def find_conversations_for_event(
        %Event{id: event_id, attributed_to_id: attributed_to_id},
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        }
      )
      when not is_nil(attributed_to_id) do
    if Actors.member?(actor_id, attributed_to_id) do
      {:ok,
       event_id
       |> Conversations.find_conversations_for_event(attributed_to_id, page, limit)
       |> conversation_participant_to_view()}
    else
      {:ok, %Page{total: 0, elements: []}}
    end
  end

  @spec find_conversations_for_event(Event.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(ConversationView.t())} | {:error, :unauthenticated}
  def find_conversations_for_event(
        %Event{id: event_id, organizer_actor_id: organizer_actor_id},
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    if organizer_actor_id == actor_id do
      {:ok,
       event_id
       |> Conversations.find_conversations_for_event(actor_id, page, limit)
       |> conversation_participant_to_view()}
    else
      {:ok, %Page{total: 0, elements: []}}
    end
  end

  def list_conversations(%Actor{id: actor_id}, %{page: page, limit: limit}, %{
        context: %{
          current_actor: %Actor{id: _current_actor_id}
        }
      }) do
    {:ok,
     actor_id
     |> Conversations.list_conversation_participants_for_actor(page, limit)
     |> conversation_participant_to_view()}
  end

  def list_conversations(%User{id: user_id}, %{page: page, limit: limit}, %{
        context: %{
          current_actor: %Actor{id: _current_actor_id}
        }
      }) do
    {:ok,
     user_id
     |> Conversations.list_conversation_participants_for_user(page, limit)
     |> conversation_participant_to_view()}
  end

  def unread_conversations_count(%Actor{id: actor_id}, _args, %{
        context: %{
          current_user: %User{} = user
        }
      }) do
    case User.owns_actor(user, actor_id) do
      {:is_owned, %Actor{}} ->
        {:ok, Conversations.count_unread_conversation_participants_for_person(actor_id)}

      _ ->
        {:error, :unauthorized}
    end
  end

  def get_conversation(_parent, %{id: conversation_participant_id}, %{
        context: %{
          current_actor: %Actor{id: performing_actor_id}
        }
      }) do
    case Conversations.get_conversation_participant(conversation_participant_id) do
      nil ->
        {:error, :not_found}

      %ConversationParticipant{actor_id: actor_id} = conversation_participant ->
        if actor_id == performing_actor_id or Actors.member?(performing_actor_id, actor_id) do
          {:ok, conversation_participant_to_view(conversation_participant)}
        else
          {:error, :not_found}
        end
    end
  end

  def get_comments_for_conversation(
        %ConversationView{origin_comment_id: origin_comment_id, actor_id: conversation_actor_id},
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: performing_actor_id}
          }
        }
      ) do
    if conversation_actor_id == performing_actor_id or
         Actors.member?(performing_actor_id, conversation_actor_id) do
      {:ok,
       Mobilizon.Discussions.get_comments_in_reply_to_comment_id(origin_comment_id, page, limit)}
    else
      {:error, :unauthorized}
    end
  end

  def create_conversation(
        _parent,
        %{actor_id: actor_id} = args,
        %{
          context: %{
            current_actor: %Actor{} = current_actor
          }
        }
      ) do
    if authorized_to_reply?(
         Map.get(args, :conversation_id),
         Map.get(args, :attributed_to_id),
         current_actor.id
       ) do
      case Comments.create_conversation(args) do
        {:ok, _activity, %Conversation{} = conversation} ->
          Absinthe.Subscription.publish(
            Endpoint,
            Conversations.count_unread_conversation_participants_for_person(current_actor.id),
            person_unread_conversations_count: current_actor.id
          )

          conversation_participant_actor =
            args |> Map.get(:attributed_to_id, actor_id) |> Actors.get_actor()

          {:ok, conversation_to_view(conversation, conversation_participant_actor)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, changeset}

        {:error, :empty_participants} ->
          {:error,
           dgettext(
             "errors",
             "Conversation needs to mention at least one participant that's not yourself"
           )}
      end
    else
      Logger.debug(
        "Actor #{current_actor.id} is not authorized to reply to conversation #{inspect(Map.get(args, :conversation_id))}"
      )

      {:error, :unauthorized}
    end
  end

  def update_conversation(_parent, %{conversation_id: conversation_participant_id, read: read}, %{
        context: %{
          current_actor: %Actor{id: current_actor_id}
        }
      }) do
    with {:no_participant,
          %ConversationParticipant{actor_id: actor_id} = conversation_participant} <-
           {:no_participant,
            Conversations.get_conversation_participant(conversation_participant_id)},
         {:valid_actor, true} <-
           {:valid_actor,
            actor_id == current_actor_id or
              Actors.member?(current_actor_id, actor_id)},
         {:ok, %ConversationParticipant{} = conversation_participant} <-
           Conversations.update_conversation_participant(conversation_participant, %{
             unread: !read
           }) do
      Absinthe.Subscription.publish(
        Endpoint,
        Conversations.count_unread_conversation_participants_for_person(actor_id),
        person_unread_conversations_count: actor_id
      )

      {:ok, conversation_participant_to_view(conversation_participant)}
    else
      {:no_participant, _} ->
        {:error, :not_found}

      {:valid_actor, _} ->
        {:error, :unauthorized}
    end
  end

  def delete_conversation(_, _, _), do: :ok

  defp conversation_participant_to_view(%Page{elements: elements} = page) do
    %Page{page | elements: Enum.map(elements, &conversation_participant_to_view/1)}
  end

  defp conversation_participant_to_view(%ConversationParticipant{} = conversation_participant) do
    value =
      conversation_participant
      |> Map.from_struct()
      |> Map.merge(Map.from_struct(conversation_participant.conversation))
      |> Map.delete(:conversation)
      |> Map.put(
        :participants,
        Enum.map(
          conversation_participant.conversation.participants,
          &conversation_participant_to_actor/1
        )
      )
      |> Map.put(:conversation_participant_id, conversation_participant.id)

    struct(ConversationView, value)
  end

  defp conversation_to_view(
         %Conversation{id: conversation_id} = conversation,
         %Actor{id: actor_id} = actor,
         unread \\ true
       ) do
    value =
      conversation
      |> Map.from_struct()
      |> Map.put(:actor, actor)
      |> Map.put(:unread, unread)
      |> Map.put(
        :conversation_participant_id,
        Conversations.get_participant_by_conversation_and_actor(conversation_id, actor_id).id
      )

    struct(ConversationView, value)
  end

  defp conversation_participant_to_actor(%Actor{} = actor), do: actor

  defp conversation_participant_to_actor(%ConversationParticipant{} = conversation_participant),
    do: conversation_participant.actor

  @spec authorized_to_reply?(String.t() | nil, String.t() | nil, String.t()) :: boolean()
  # Not a reply
  defp authorized_to_reply?(conversation_id, _attributed_to_id, _current_actor_id)
       when is_nil(conversation_id),
       do: true

  # We are authorized to reply if we are one of the participants, or if we a a member of a participant group
  defp authorized_to_reply?(conversation_id, attributed_to_id, current_actor_id) do
    case Conversations.get_conversation(conversation_id) do
      nil ->
        false

      %Conversation{participants: participants} ->
        participant_ids = Enum.map(participants, fn participant -> to_string(participant.id) end)

        to_string(current_actor_id) in participant_ids or
          Enum.any?(participant_ids, fn participant_id ->
            Actors.member?(current_actor_id, participant_id) and
              attributed_to_id == participant_id
          end)
    end
  end
end
