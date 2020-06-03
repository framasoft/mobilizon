defmodule Mobilizon.GraphQL.Schema.Conversations.ConversationType do
  @moduledoc """
  Schema representation for Conversation
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Actors
  alias Mobilizon.GraphQL.Resolvers.Conversation

  @desc "A conversation"
  object :conversation do
    field(:id, :id, description: "Internal ID for this conversation")
    field(:title, :string)
    field(:slug, :string)
    field(:last_comment, :comment)

    field :comments, :paginated_comment_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Conversation.get_comments_for_conversation/3)
      description("The comments for the conversation")
    end

    field(:creator, :person, resolve: dataloader(Actors))
    field(:actor, :actor, resolve: dataloader(Actors))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :paginated_conversation_list do
    field(:elements, list_of(:conversation), description: "A list of conversation")
    field(:total, :integer, description: "The total number of comments in the list")
  end

  object :conversation_queries do
    @desc "Get a conversation"
    field :conversation, type: :conversation do
      arg(:id, non_null(:id))
      resolve(&Conversation.get_conversation/3)
    end
  end

  object :conversation_mutations do
    @desc "Create a conversation"
    field :create_conversation, type: :conversation do
      arg(:title, non_null(:string))
      arg(:text, non_null(:string))
      arg(:actor_id, non_null(:id))
      arg(:creator_id, non_null(:id))

      resolve(&Conversation.create_conversation/3)
    end

    field :reply_to_conversation, type: :conversation do
      arg(:conversation_id, non_null(:id))
      arg(:text, non_null(:string))
      resolve(&Conversation.reply_to_conversation/3)
    end

    field :update_conversation, type: :conversation do
      arg(:title, non_null(:string))
      arg(:conversation_id, non_null(:id))
      resolve(&Conversation.update_conversation/3)
    end

    field :delete_conversation, type: :conversation do
      arg(:conversation_id, non_null(:id))

      # resolve(&Conversation.delete_conversation/3)
    end
  end
end
