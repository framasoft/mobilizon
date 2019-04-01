import gql from 'graphql-tag';

export const LOGGED_PERSON = gql`
query {
  loggedPerson {
    id,
    avatarUrl,
    preferredUsername,
  }
}`;

export const CREATE_FEED_TOKEN_ACTOR = gql`
mutation createFeedToken($actor_id: Int!) {
  createFeedToken(actor_id: $actor_id) {
    token,
    actor {
      id
    },
    user {
      id
    }
  }
}`;

export const CREATE_FEED_TOKEN = gql`
mutation {
  createFeedToken {
    token,
    actor {
      id
    },
    user {
      id
    }
  }
}`;

export const DELETE_FEED_TOKEN = gql`
mutation deleteFeedToken($token: String!) {
    deleteFeedToken(token: $token) {
        actor {
          id
        },
        user {
          id
        }
      }
    }
`;
