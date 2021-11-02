import gql from "graphql-tag";

export const ACTOR_FRAGMENT = gql`
  fragment ActorFragment on Actor {
    id
    avatar {
      id
      url
    }
    type
    preferredUsername
    name
    domain
    summary
    url
  }
`;

export const FETCH_PERSON = gql`
  query ($username: String!) {
    fetchPerson(preferredUsername: $username) {
      ...ActorFragment
      suspended
      mediaSize
      avatar {
        id
        name
        url
      }
      banner {
        id
        url
      }
      feedTokens {
        token
      }
      organizedEvents {
        total
        elements {
          id
          uuid
          title
          beginsOn
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const GET_PERSON = gql`
  query Person(
    $actorId: ID!
    $organizedEventsPage: Int
    $organizedEventsLimit: Int
    $participationPage: Int
    $participationLimit: Int
    $membershipsPage: Int
    $membershipsLimit: Int
  ) {
    person(id: $actorId) {
      ...ActorFragment
      suspended
      mediaSize
      avatar {
        id
        name
        url
      }
      banner {
        id
        url
      }
      feedTokens {
        token
      }
      organizedEvents(
        page: $organizedEventsPage
        limit: $organizedEventsLimit
      ) {
        total
        elements {
          id
          uuid
          title
          beginsOn
        }
      }
      participations(page: $participationPage, limit: $participationLimit) {
        total
        elements {
          id
          event {
            id
            uuid
            title
            beginsOn
          }
        }
      }
      memberships(page: $membershipsPage, limit: $membershipsLimit) {
        total
        elements {
          id
          role
          insertedAt
          parent {
            ...ActorFragment
          }
        }
      }
      user {
        id
        email
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const PERSON_FRAGMENT = gql`
  fragment PersonFragment on Person {
    id
    avatar {
      id
      url
    }
    type
    preferredUsername
    domain
    name
  }
`;

export const LIST_PROFILES = gql`
  query ListProfiles(
    $preferredUsername: String
    $name: String
    $domain: String
    $local: Boolean
    $suspended: Boolean
    $page: Int
    $limit: Int
  ) {
    persons(
      preferredUsername: $preferredUsername
      name: $name
      domain: $domain
      local: $local
      suspended: $suspended
      page: $page
      limit: $limit
    ) {
      total
      elements {
        ...ActorFragment
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_DEFAULT_ACTOR = gql`
  mutation ChangeDefaultActor($preferredUsername: String!) {
    changeDefaultActor(preferredUsername: $preferredUsername) {
      id
      defaultActor {
        id
      }
    }
  }
`;

export const CURRENT_ACTOR_CLIENT = gql`
  query currentActor {
    currentActor @client {
      id
      preferredUsername
      name
      avatar
    }
  }
`;

export const UPDATE_CURRENT_ACTOR_CLIENT = gql`
  mutation UpdateCurrentActor(
    $id: String!
    $avatar: String
    $preferredUsername: String!
    $name: String!
  ) {
    updateCurrentActor(
      id: $id
      avatar: $avatar
      preferredUsername: $preferredUsername
      name: $name
    ) @client
  }
`;

export const LOGGED_USER_DRAFTS = gql`
  query LoggedUserDrafts($page: Int, $limit: Int) {
    loggedUser {
      id
      drafts(page: $page, limit: $limit) {
        id
        uuid
        title
        draft
        picture {
          id
          url
          alt
        }
        beginsOn
        visibility
        organizerActor {
          ...ActorFragment
        }
        participantStats {
          going
          notApproved
        }
        options {
          maximumAttendeeCapacity
          remainingAttendeeCapacity
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const LOGGED_USER_MEMBERSHIPS = gql`
  query LoggedUserMemberships($page: Int, $limit: Int) {
    loggedUser {
      id
      memberships(page: $page, limit: $limit) {
        total
        elements {
          id
          role
          actor {
            ...ActorFragment
          }
          parent {
            ...ActorFragment
            organizedEvents {
              elements {
                id
                title
                picture {
                  id
                  url
                }
              }
              total
            }
          }
          invitedBy {
            ...ActorFragment
          }
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const IDENTITIES = gql`
  query Identities {
    identities {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const PERSON_MEMBERSHIPS = gql`
  query PersonMemberships($id: ID!) {
    person(id: $id) {
      id
      memberships {
        total
        elements {
          id
          role
          parent {
            ...ActorFragment
          }
          invitedBy {
            ...ActorFragment
          }
          insertedAt
          updatedAt
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const PERSON_STATUS_GROUP = gql`
  query PersonMembershipGroup($id: ID!, $group: String!) {
    person(id: $id) {
      id
      memberships(group: $group) {
        total
        elements {
          id
          role
          parent {
            ...ActorFragment
          }
          invitedBy {
            ...ActorFragment
          }
          insertedAt
          updatedAt
        }
      }
      follows(group: $group) {
        total
        elements {
          id
          notify
          approved
          target_actor {
            ...ActorFragment
          }
          actor {
            ...ActorFragment
          }
          insertedAt
          updatedAt
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED = gql`
  subscription GroupMembershipSubscriptionChanged(
    $actorId: ID!
    $group: String!
  ) {
    groupMembershipChanged(personId: $actorId, group: $group) {
      id
      memberships {
        total
        elements {
          id
          role
          parent {
            ...ActorFragment
          }
          invitedBy {
            ...ActorFragment
          }
          insertedAt
          updatedAt
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const CREATE_PERSON = gql`
  mutation CreatePerson(
    $preferredUsername: String!
    $name: String!
    $summary: String
    $avatar: MediaInput
  ) {
    createPerson(
      preferredUsername: $preferredUsername
      name: $name
      summary: $summary
      avatar: $avatar
    ) {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_PERSON = gql`
  mutation UpdatePerson(
    $id: ID!
    $name: String
    $summary: String
    $avatar: MediaInput
  ) {
    updatePerson(id: $id, name: $name, summary: $summary, avatar: $avatar) {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const DELETE_PERSON = gql`
  mutation DeletePerson($id: ID!) {
    deletePerson(id: $id) {
      preferredUsername
    }
  }
`;

/**
 * This one is used only to register the first account.
 * Prefer CREATE_PERSON when creating another identity
 */
export const REGISTER_PERSON = gql`
  mutation (
    $preferredUsername: String!
    $name: String!
    $summary: String!
    $email: String!
  ) {
    registerPerson(
      preferredUsername: $preferredUsername
      name: $name
      summary: $summary
      email: $email
    ) {
      ...ActorFragment
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const SUSPEND_PROFILE = gql`
  mutation SuspendProfile($id: ID!) {
    suspendProfile(id: $id) {
      id
    }
  }
`;

export const UNSUSPEND_PROFILE = gql`
  mutation UnSuspendProfile($id: ID!) {
    unsuspendProfile(id: $id) {
      id
    }
  }
`;
