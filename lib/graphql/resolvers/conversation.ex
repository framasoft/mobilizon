defmodule Mobilizon.GraphQL.Resolvers.Conversation do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Conversations, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation, as: ConversationModel
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  def find_conversations_for_actor(
        %Actor{id: group_id},
        _args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      {:ok, Conversations.find_conversations_for_actor(group_id)}
    else
      {:member, false} ->
        {:ok, %Page{total: 0, elements: []}}
    end
  end

  def find_conversations_for_actor(%Actor{}, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  def get_conversation(_parent, %{id: id}, _resolution) do
    {:ok, Conversations.get_conversation(id)}
  end

  def get_comments_for_conversation(
        %ConversationModel{id: conversation_id},
        %{page: page, limit: limit},
        _resolution
      ) do
    {:ok, Conversations.get_comments_for_conversation(conversation_id, page, limit)}
  end

  def create_conversation(
        _parent,
        %{title: title, text: text, actor_id: actor_id, creator_id: creator_id},
        _resolution
      ) do
    with {:ok, %ConversationModel{} = conversation} <-
           Conversations.create_conversation(%{
             title: title,
             text: text,
             actor_id: actor_id,
             creator_id: creator_id
           }) do
      {:ok, conversation}
    end
  end

  def reply_to_conversation(
        _parent,
        %{text: text, conversation_id: conversation_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:no_conversation, %ConversationModel{} = conversation} <-
           {:no_conversation, Conversations.get_conversation(conversation_id)},
         {:ok, %ConversationModel{} = conversation} <-
           Conversations.reply_to_conversation(
             conversation,
             %{
               text: text,
               actor_id: actor_id
             }
           ) do
      {:ok, conversation}
    end
  end

  @spec update_conversation(map(), map(), map()) :: {:ok, ConversationModel.t()}
  def update_conversation(
        _parent,
        %{title: title, conversation_id: conversation_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:no_conversation, %ConversationModel{creator_id: creator_id} = conversation} <-
           {:no_conversation, Conversations.get_conversation(conversation_id)},
         {:check_access, true} <- {:check_access, actor_id == creator_id},
         {:ok, %ConversationModel{} = conversation} <-
           Conversations.update_conversation(
             conversation,
             %{
               title: title
             }
           ) do
      {:ok, conversation}
    end
  end
end
