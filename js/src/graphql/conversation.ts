import gql from "graphql-tag";

export const CONVERSATION_BASIC_FIELDS_FRAGMENT = gql`
  fragment ConversationBasicFields on Conversation {
    id
    title
    slug
    lastComment {
      id
      text
      actor {
        preferredUsername
        avatar {
          url
        }
      }
    }
  }
`;

export const CONVERSATION_FIELDS_FOR_REPLY_FRAGMENT = gql`
  fragment ConversationFieldsReply on Conversation {
    id
    title
    slug
    lastComment {
      id
      text
      updatedAt
      actor {
        id
        preferredUsername
        avatar {
          url
        }
      }
    }
    actor {
      id
      preferredUsername
    }
    creator {
      id
      preferredUsername
    }
  }
`;

export const CONVERSATION_FIELDS_FRAGMENT = gql`
  fragment ConversationFields on Conversation {
    id
    title
    slug
    lastComment {
      id
      text
      updatedAt
    }
    actor {
      id
      preferredUsername
    }
    creator {
      id
      preferredUsername
    }
  }
`;

export const CREATE_CONVERSATION = gql`
  mutation createConversation($title: String!, $creatorId: ID!, $actorId: ID!, $text: String!) {
    createConversation(title: $title, text: $text, creatorId: $creatorId, actorId: $actorId) {
      ...ConversationFields
    }
  }
  ${CONVERSATION_FIELDS_FRAGMENT}
`;

export const REPLY_TO_CONVERSATION = gql`
  mutation replyToConversation($conversationId: ID!, $text: String!) {
    replyToConversation(conversationId: $conversationId, text: $text) {
      ...ConversationFieldsReply
    }
  }
  ${CONVERSATION_FIELDS_FOR_REPLY_FRAGMENT}
`;

export const GET_CONVERSATION = gql`
  query getConversation($id: ID!, $page: Int, $limit: Int) {
    conversation(id: $id) {
      comments(page: $page, limit: $limit) {
        total
        elements {
          id
          text
          actor {
            id
            avatar {
              url
            }
            preferredUsername
          }
          insertedAt
          updatedAt
        }
      }
      ...ConversationFields
    }
  }
  ${CONVERSATION_FIELDS_FRAGMENT}
`;

export const UPDATE_CONVERSATION = gql`
  mutation updateConversation($conversationId: ID!, $title: String!) {
    updateConversation(conversationId: $conversationId, title: $title) {
      ...ConversationFields
    }
  }
  ${CONVERSATION_FIELDS_FRAGMENT}
`;
