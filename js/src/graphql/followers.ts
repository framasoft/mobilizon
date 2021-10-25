import gql from "graphql-tag";

export const GROUP_FOLLOWERS = gql`
  query (
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

export const FOLLOW_GROUP = gql`
  mutation FollowGroup($groupId: ID!, $notify: Boolean) {
    followGroup(groupId: $groupId, notify: $notify) {
      id
    }
  }
`;

export const UNFOLLOW_GROUP = gql`
  mutation UnfollowGroup($groupId: ID!) {
    unfollowGroup(groupId: $groupId) {
      id
    }
  }
`;

export const UPDATE_GROUP_FOLLOW = gql`
  mutation UpdateGroupFollow($followId: ID!, $notify: Boolean) {
    updateGroupFollow(followId: $followId, notify: $notify) {
      id
      notify
    }
  }
`;
