import gql from "graphql-tag";

export const GROUP_FOLLOWERS = gql`
  query(
    $name: String!
    $followersPage: Int
    $followersLimit: Int
    $approved: Boolean
  ) {
    group(preferredUsername: $name) {
      id
      preferredUsername
      name
      domain
      followers(
        page: $followersPage
        limit: $followersLimit
        approved: $approved
      ) {
        total
        elements {
          id
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
          approved
          insertedAt
          updatedAt
        }
      }
    }
  }
`;

export const UPDATE_FOLLOWER = gql`
  mutation UpdateFollower($id: ID!, $approved: Boolean) {
    updateFollower(id: $id, approved: $approved) {
      id
      approved
    }
  }
`;
