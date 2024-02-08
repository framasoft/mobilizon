import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { COMMENT_FIELDS_FRAGMENT } from "./comment";

export const CONVERSATION_QUERY_FRAGMENT = gql`
  fragment ConversationQuery on Conversation {
    id
    conversationParticipantId
    actor {
      ...ActorFragment
    }
    lastComment {
      ...CommentFields
    }
    originComment {
      ...CommentFields
    }
    participants {
      ...ActorFragment
    }
    event {
      id
      uuid
      title
      organizerActor {
        id
      }
      attributedTo {
        id
      }
      picture {
        id
        url
        name
        metadata {
          width
          height
          blurhash
        }
      }
    }
    unread
    insertedAt
    updatedAt
  }
  ${ACTOR_FRAGMENT}
  ${COMMENT_FIELDS_FRAGMENT}
`;

export const CONVERSATIONS_QUERY_FRAGMENT = gql`
  fragment ConversationsQuery on PaginatedConversationList {
    total
    elements {
      ...ConversationQuery
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;

export const SEND_EVENT_PRIVATE_MESSAGE_MUTATION = gql`
  mutation SendEventPrivateMessageMutation(
    $text: String!
    $actorId: ID!
    $eventId: ID!
    $roles: [ParticipantRoleEnum]
    $language: String
  ) {
    sendEventPrivateMessage(
      text: $text
      actorId: $actorId
      eventId: $eventId
      roles: $roles
      language: $language
    ) {
      ...ConversationQuery
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;

export const GET_CONVERSATION = gql`
  query GetConversation($id: ID!, $page: Int, $limit: Int) {
    conversation(id: $id) {
      ...ConversationQuery
      comments(page: $page, limit: $limit) @connection(key: "comments") {
        total
        elements {
          id
          text
          actor {
            ...ActorFragment
          }
          insertedAt
          updatedAt
          deletedAt
          publishedAt
        }
      }
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;

export const POST_PRIVATE_MESSAGE_MUTATION = gql`
  mutation PostPrivateMessageMutation(
    $text: String!
    $actorId: ID!
    $language: String
    $mentions: [String]
  ) {
    postPrivateMessage(
      text: $text
      actorId: $actorId
      language: $language
      mentions: $mentions
    ) {
      ...ConversationQuery
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;

export const REPLY_TO_PRIVATE_MESSAGE_MUTATION = gql`
  mutation ReplyToPrivateMessageMutation(
    $text: String!
    $actorId: ID!
    $attributedToId: ID
    $language: String
    $conversationId: ID!
    $mentions: [String]
  ) {
    postPrivateMessage(
      text: $text
      actorId: $actorId
      attributedToId: $attributedToId
      language: $language
      conversationId: $conversationId
      mentions: $mentions
    ) {
      ...ConversationQuery
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;

export const CONVERSATION_COMMENT_CHANGED = gql`
  subscription ConversationCommentChanged($id: ID!) {
    conversationCommentChanged(id: $id) {
      id
      lastComment {
        id
        text
        updatedAt
        insertedAt
        deletedAt
        publishedAt
        actor {
          ...ActorFragment
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const MARK_CONVERSATION_AS_READ = gql`
  mutation MarkConversationAsRead($id: ID!, $read: Boolean!) {
    updateConversation(conversationId: $id, read: $read) {
      ...ConversationQuery
    }
  }
  ${CONVERSATION_QUERY_FRAGMENT}
`;
