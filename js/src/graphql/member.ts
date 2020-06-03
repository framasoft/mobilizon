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
