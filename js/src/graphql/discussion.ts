import gql from "graphql-tag";

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
        id
        preferredUsername
        domain
        avatar {
          id
          url
        }
      }
      publishedAt
      deletedAt
    }
  }
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
        id
        preferredUsername
        domain
        avatar {
          id
          url
        }
      }
    }
    actor {
      id
      preferredUsername
      domain
    }
    creator {
      id
      preferredUsername
      domain
    }
  }
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
    }
    actor {
      id
      domain
      name
      preferredUsername
    }
    creator {
      id
      domain
      name
      preferredUsername
    }
  }
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
      comments(page: $page, limit: $limit)
        @connection(key: "discussion-comments", filter: ["slug"]) {
        total
        elements {
          id
          text
          actor {
            id
            avatar {
              id
              url
            }
            name
            domain
            preferredUsername
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
  subscription($slug: String!) {
    discussionCommentChanged(slug: $slug) {
      id
      lastComment {
        id
        text
        updatedAt
        insertedAt
        actor {
          id
          preferredUsername
          name
          domain
          avatar {
            id
            url
          }
        }
      }
    }
  }
`;
