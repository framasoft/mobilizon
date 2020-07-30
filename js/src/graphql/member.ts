import gql from "graphql-tag";

export const INVITE_MEMBER = gql`
  mutation InviteMember($groupId: ID!, $targetActorUsername: String!) {
    inviteMember(groupId: $groupId, targetActorUsername: $targetActorUsername) {
      id
      role
      parent {
        id
      }
      actor {
        id
      }
    }
  }
`;

export const ACCEPT_INVITATION = gql`
  mutation AcceptInvitation($id: ID!) {
    acceptInvitation(id: $id) {
      id
    }
  }
`;

export const GROUP_MEMBERS = gql`
  query($name: String!, $roles: String, $page: Int, $limit: Int) {
    group(preferredUsername: $name) {
      id
      url
      name
      domain
      preferredUsername
      members(page: $page, limit: $limit, roles: $roles) {
        elements {
          role
          actor {
            id
            name
            domain
            preferredUsername
            avatar {
              url
            }
          }
          insertedAt
        }
        total
      }
    }
  }
`;
