import gql from "graphql-tag";
import { DISCUSSION_BASIC_FIELDS_FRAGMENT } from "./discussion";
import { RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT } from "./resources";
import { POST_BASIC_FIELDS } from "./post";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { TAG_FRAGMENT } from "./tags";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";

export const LIST_GROUPS = gql`
  query ListGroups(
    $preferredUsername: String
    $name: String
    $domain: String
    $local: Boolean
    $suspended: Boolean
    $page: Int
    $limit: Int
  ) {
    groups(
      preferredUsername: $preferredUsername
      name: $name
      domain: $domain
      local: $local
      suspended: $suspended
      page: $page
      limit: $limit
    ) {
      elements {
        ...ActorFragment
        suspended
        avatar {
          id
          url
        }
        banner {
          id
          url
        }
        organizedEvents {
          elements {
            id
            uuid
            title
            beginsOn
          }
          total
        }
      }
      total
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const GROUP_FIELDS_FRAGMENTS = gql`
  fragment GroupFullFields on Group {
    ...ActorFragment
    suspended
    visibility
    openness
    manuallyApprovesFollowers
    physicalAddress {
      description
      street
      locality
      postalCode
      region
      country
      geom
      type
      id
      originId
      url
    }
    avatar {
      id
      url
      name
      metadata {
        width
        height
        blurhash
      }
    }
    banner {
      id
      url
      name
      metadata {
        width
        height
        blurhash
      }
    }
    organizedEvents(
      afterDatetime: $afterDateTime
      beforeDatetime: $beforeDateTime
      page: $organisedEventsPage
      limit: $organisedEventsLimit
    ) {
      elements {
        id
        uuid
        title
        beginsOn
        draft
        options {
          maximumAttendeeCapacity
        }
        participantStats {
          participant
          notApproved
        }
        attributedTo {
          ...ActorFragment
        }
        organizerActor {
          ...ActorFragment
        }
        picture {
          id
          url
        }
        physicalAddress {
          ...AdressFragment
        }
        options {
          ...EventOptions
        }
        tags {
          ...TagFragment
        }
      }
      total
    }
    discussions(page: $discussionsPage, limit: $discussionsLimit) {
      total
      elements {
        ...DiscussionBasicFields
      }
    }
    posts(page: $postsPage, limit: $postsLimit) {
      total
      elements {
        ...PostBasicFields
      }
    }
    members(page: $membersPage, limit: $membersLimit) {
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
    resources(page: 1, limit: 3) {
      elements {
        id
        title
        resourceUrl
        summary
        updatedAt
        type
        path
        metadata {
          ...ResourceMetadataBasicFields
        }
      }
      total
    }
    todoLists {
      elements {
        id
        title
        todos {
          elements {
            id
            title
            status
            dueDate
            assignedTo {
              id
              preferredUsername
            }
          }
          total
        }
      }
      total
    }
  }
  ${ACTOR_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
  ${TAG_FRAGMENT}
`;

export const FETCH_GROUP = gql`
  query FetchGroup(
    $name: String!
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $organisedEventsPage: Int
    $organisedEventsLimit: Int
    $postsPage: Int
    $postsLimit: Int
    $membersPage: Int
    $membersLimit: Int
    $discussionsPage: Int
    $discussionsLimit: Int
  ) {
    group(preferredUsername: $name) {
      ...GroupFullFields
    }
  }
  ${GROUP_FIELDS_FRAGMENTS}
  ${DISCUSSION_BASIC_FIELDS_FRAGMENT}
  ${POST_BASIC_FIELDS}
  ${RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT}
`;

export const GET_GROUP = gql`
  query GetGroup(
    $id: ID!
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $organisedEventsPage: Int
    $organisedEventsLimit: Int
    $postsPage: Int
    $postsLimit: Int
    $membersPage: Int
    $membersLimit: Int
    $discussionsPage: Int
    $discussionsLimit: Int
  ) {
    getGroup(id: $id) {
      mediaSize
      ...GroupFullFields
    }
  }
  ${GROUP_FIELDS_FRAGMENTS}
  ${DISCUSSION_BASIC_FIELDS_FRAGMENT}
  ${POST_BASIC_FIELDS}
  ${RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT}
`;

export const CREATE_GROUP = gql`
  mutation CreateGroup(
    $preferredUsername: String!
    $name: String!
    $summary: String
    $avatar: MediaInput
    $banner: MediaInput
  ) {
    createGroup(
      preferredUsername: $preferredUsername
      name: $name
      summary: $summary
      banner: $banner
      avatar: $avatar
    ) {
      ...ActorFragment
      banner {
        id
        url
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_GROUP = gql`
  mutation UpdateGroup(
    $id: ID!
    $name: String
    $summary: String
    $avatar: MediaInput
    $banner: MediaInput
    $visibility: GroupVisibility
    $openness: Openness
    $physicalAddress: AddressInput
    $manuallyApprovesFollowers: Boolean
  ) {
    updateGroup(
      id: $id
      name: $name
      summary: $summary
      banner: $banner
      avatar: $avatar
      visibility: $visibility
      openness: $openness
      physicalAddress: $physicalAddress
      manuallyApprovesFollowers: $manuallyApprovesFollowers
    ) {
      ...ActorFragment
      visibility
      openness
      manuallyApprovesFollowers
      banner {
        id
        url
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const DELETE_GROUP = gql`
  mutation DeleteGroup($groupId: ID!) {
    deleteGroup(groupId: $groupId) {
      id
    }
  }
`;

export const LEAVE_GROUP = gql`
  mutation LeaveGroup($groupId: ID!) {
    leaveGroup(groupId: $groupId) {
      id
    }
  }
`;

export const REFRESH_PROFILE = gql`
  mutation RefreshProfile($actorId: ID!) {
    refreshProfile(id: $actorId) {
      id
    }
  }
`;

export const GROUP_TIMELINE = gql`
  query GroupTimeline(
    $preferredUsername: String!
    $type: ActivityType
    $author: ActivityAuthor
    $page: Int
    $limit: Int
  ) {
    group(preferredUsername: $preferredUsername) {
      ...ActorFragment
      activity(type: $type, author: $author, page: $page, limit: $limit) {
        total
        elements {
          id
          insertedAt
          subject
          subjectParams {
            key
            value
          }
          type
          author {
            ...ActorFragment
          }
          group {
            ...ActorFragment
          }
          object {
            ... on Event {
              id
              title
            }
            ... on Post {
              id
              title
            }
            ... on Member {
              id
              actor {
                ...ActorFragment
              }
            }
            ... on Resource {
              id
              title
              path
              type
            }
            ... on Discussion {
              id
              title
              slug
            }
            ... on Comment {
              id
            }
            ... on Group {
              ...ActorFragment
              visibility
              openness
              physicalAddress {
                id
              }
              banner {
                id
                url
              }
            }
          }
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;
