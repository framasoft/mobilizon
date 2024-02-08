defmodule Mobilizon.GraphQL.Schema.ConversationType do
  @moduledoc """
  Schema representation for conversation
  """
  use Absinthe.Schema.Notation

  # import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  # alias Mobilizon.Actors
  alias Mobilizon.GraphQL.Resolvers.Conversation

  @desc "A conversation"
  object :conversation do
    meta(:authorize, :user)
    interfaces([:activity_object])
    field(:id, :id, description: "Internal ID for this conversation")

    field(:conversation_participant_id, :id,
      description: "Internal ID for the conversation participant"
    )

    field(:last_comment, :comment, description: "The last comment of the conversation")
    field(:origin_comment, :comment, description: "The first comment of the conversation")

    field :comments, :paginated_comment_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Conversation.get_comments_for_conversation/3)
      description("The comments for the conversation")
    end

    field(:participants, list_of(:person),
      # resolve: dataloader(Actors),
      description: "The list of participants to the conversation"
    )

    field(:event, :event, description: "The event this conversation is associated to")

    field(:actor, :person,
      # resolve: dataloader(Actors),
      description: "The actor concerned by the conversation"
    )

    field(:unread, :boolean, description: "Whether this conversation is unread")

    field(:inserted_at, :datetime, description: "When was this conversation's created")
    field(:updated_at, :datetime, description: "When was this conversation's updated")
  end

  @desc "A paginated list of conversations"
  object :paginated_conversation_list do
    meta(:authorize, :user)
    field(:elements, list_of(:conversation), description: "A list of conversations")
    field(:total, :integer, description: "The total number of conversations in the list")
  end

  object :conversation_queries do
    @desc "Get a conversation"
    field :conversation, type: :conversation do
      arg(:id, :id, description: "The conversation's ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Conversations.Conversation,
        rule: :"read:conversations",
        args: %{id: :id}
      )

      resolve(&Conversation.get_conversation/3)
    end
  end

  object :conversation_mutations do
    @desc "Post a private message"
    field :post_private_message, type: :conversation do
      arg(:text, non_null(:string), description: "The conversation's first comment body")
      arg(:actor_id, non_null(:id), description: "The profile ID to create the conversation as")
      arg(:attributed_to_id, :id, description: "The group ID to attribute the conversation to")
      arg(:conversation_id, :id, description: "The conversation ID to reply to")
      arg(:language, :string, description: "The comment language", default_value: "und")
      arg(:mentions, list_of(:string), description: "A list of federated usernames to mention")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Conversations.ConversationParticipant,
        rule: :"write:conversation:create",
        args: %{actor_id: :actor_id}
      )

      resolve(&Conversation.create_conversation/3)
    end

    @desc "Update a conversation"
    field :update_conversation, type: :conversation do
      arg(:conversation_id, non_null(:id), description: "The conversation's ID")
      arg(:read, non_null(:boolean), description: "Whether the conversation is read or not")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Conversations.Conversation,
        rule: :"write:conversation:update",
        args: %{id: :conversation_id}
      )

      resolve(&Conversation.update_conversation/3)
    end

    @desc "Delete a conversation"
    field :delete_conversation, type: :conversation do
      arg(:conversation_id, non_null(:id), description: "The conversation's ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Conversations.Conversation,
        rule: :"write:conversation:delete",
        args: %{id: :conversation_id}
      )

      resolve(&Conversation.delete_conversation/3)
    end
  end

  object :conversation_subscriptions do
    @desc "Notify when a conversation changed"
    field :conversation_comment_changed, :conversation do
      arg(:id, non_null(:id), description: "The conversation's ID")

      config(fn args, _ ->
        {:ok, topic: args.id}
      end)
    end
  end
end
