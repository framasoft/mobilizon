import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const DISCUSSION_BASIC_FIELDS_FRAGMENT = gql`
  fragment DiscussionBasicFields on Discussion {
    id
    title
    slug
    insertedAt
    updatedAt
    lastComment {
      id
      text
      actor {
        ...ActorFragment
      }
      publishedAt
      deletedAt
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const DISCUSSION_FIELDS_FOR_REPLY_FRAGMENT = gql`
  fragment DiscussionFieldsReply on Discussion {
    id
    title
    slug
    lastComment {
      id
      text
      updatedAt
      actor {
        ...ActorFragment
      }
    }
    actor {
      ...ActorFragment
    }
    creator {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const DISCUSSION_FIELDS_FRAGMENT = gql`
  fragment DiscussionFields on Discussion {
    id
    title
    slug
    lastComment {
      id
      text
      insertedAt
      updatedAt
      deletedAt
      publishedAt
      actor {
        ...ActorFragment
      }
    }
    actor {
      ...ActorFragment
    }
    creator {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const CREATE_DISCUSSION = gql`
  mutation createDiscussion($title: String!, $actorId: ID!, $text: String!) {
    createDiscussion(title: $title, text: $text, actorId: $actorId) {
      ...DiscussionFields
    }
  }
  ${DISCUSSION_FIELDS_FRAGMENT}
`;

export const REPLY_TO_DISCUSSION = gql`
  mutation replyToDiscussion($discussionId: ID!, $text: String!) {
    replyToDiscussion(discussionId: $discussionId, text: $text) {
      ...DiscussionFields
    }
  }
  ${DISCUSSION_FIELDS_FRAGMENT}
`;

export const GET_DISCUSSION = gql`
  query getDiscussion($slug: String!, $page: Int, $limit: Int) {
    discussion(slug: $slug) {
      comments(page: $page, limit: $limit) {
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
      ...DiscussionFields
    }
  }
  ${DISCUSSION_FIELDS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_DISCUSSION = gql`
  mutation updateDiscussion($discussionId: ID!, $title: String!) {
    updateDiscussion(discussionId: $discussionId, title: $title) {
      ...DiscussionFields
    }
  }
  ${DISCUSSION_FIELDS_FRAGMENT}
`;

export const DELETE_DISCUSSION = gql`
  mutation deleteDiscussion($discussionId: ID!) {
    deleteDiscussion(discussionId: $discussionId) {
      id
    }
  }
`;

export const DISCUSSION_COMMENT_CHANGED = gql`
  subscription ($slug: String!) {
    discussionCommentChanged(slug: $slug) {
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
