import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const MEMBER_FRAGMENT = gql`
  fragment MemberFragment on Member {
    id
    role
    parent {
      ...ActorFragment
    }
    actor {
      ...ActorFragment
    }
    insertedAt
  }
  ${ACTOR_FRAGMENT}
`;

export const INVITE_MEMBER = gql`
  mutation InviteMember($groupId: ID!, $targetActorUsername: String!) {
    inviteMember(groupId: $groupId, targetActorUsername: $targetActorUsername) {
      ...MemberFragment
    }
  }
  ${MEMBER_FRAGMENT}
`;

export const ACCEPT_INVITATION = gql`
  mutation AcceptInvitation($id: ID!) {
    acceptInvitation(id: $id) {
      ...MemberFragment
    }
  }
  ${MEMBER_FRAGMENT}
`;

export const REJECT_INVITATION = gql`
  mutation RejectInvitation($id: ID!) {
    rejectInvitation(id: $id) {
      ...MemberFragment
    }
  }
  ${MEMBER_FRAGMENT}
`;

export const GROUP_MEMBERS = gql`
  query ($name: String!, $roles: String, $page: Int, $limit: Int) {
    group(preferredUsername: $name) {
      ...ActorFragment
      members(page: $page, limit: $limit, roles: $roles) {
        elements {
          id
          role
          actor {
            ...ActorFragment
          }
          insertedAt
        }
        total
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_MEMBER = gql`
  mutation UpdateMember($memberId: ID!, $role: MemberRoleEnum!) {
    updateMember(memberId: $memberId, role: $role) {
      id
      role
    }
  }
`;

export const REMOVE_MEMBER = gql`
  mutation RemoveMember($memberId: ID!, $exclude: Boolean) {
    removeMember(memberId: $memberId, exclude: $exclude) {
      id
    }
  }
`;

export const APPROVE_MEMBER = gql`
  mutation ApproveMember($memberId: ID!) {
    approveMember(memberId: $memberId) {
      ...MemberFragment
    }
  }
  ${MEMBER_FRAGMENT}
`;

export const JOIN_GROUP = gql`
  mutation JoinGroup($groupId: ID!) {
    joinGroup(groupId: $groupId) {
      ...MemberFragment
    }
  }
  ${MEMBER_FRAGMENT}
`;
