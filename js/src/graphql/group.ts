import gql from "graphql-tag";
import { DISCUSSION_BASIC_FIELDS_FRAGMENT } from "./discussion";
import { RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT } from "./resources";
import { POST_BASIC_FIELDS } from "./post";

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
        id
        url
        name
        domain
        summary
        preferredUsername
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
`;

export const GROUP_FIELDS_FRAGMENTS = gql`
  fragment GroupFullFields on Group {
    id
    url
    name
    domain
    summary
    preferredUsername
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
    }
    avatar {
      id
      url
    }
    banner {
      id
      url
    }
    organizedEvents(
      afterDatetime: $afterDateTime
      beforeDatetime: $beforeDateTime
      page: $organisedEventsPage
      limit: $organisedEventslimit
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
          id
          preferredUsername
          name
          domain
        }
        organizerActor {
          id
          preferredUsername
          name
          domain
        }
      }
      total
    }
    discussions {
      total
      elements {
        ...DiscussionBasicFields
      }
    }
    posts {
      total
      elements {
        ...PostBasicFields
      }
    }
    members {
      elements {
        id
        role
        actor {
          id
          name
          domain
          preferredUsername
          avatar {
            id
            url
          }
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
`;

export const FETCH_GROUP = gql`
  query(
    $name: String!
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $organisedEventsPage: Int
    $organisedEventslimit: Int
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
  query(
    $id: ID!
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $organisedEventsPage: Int
    $organisedEventslimit: Int
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
      id
      preferredUsername
      name
      domain
      summary
      avatar {
        id
        url
      }
      banner {
        id
        url
      }
    }
  }
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
      id
      preferredUsername
      name
      summary
      visibility
      openness
      manuallyApprovesFollowers
      avatar {
        id
        url
      }
      banner {
        id
        url
      }
    }
  }
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
    $page: Int
    $limit: Int
  ) {
    group(preferredUsername: $preferredUsername) {
      id
      preferredUsername
      domain
      name
      activity(type: $type, page: $page, limit: $limit) {
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
            id
            preferredUsername
            name
            domain
            avatar {
              id
              url
            }
          }
          group {
            id
            preferredUsername
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
                id
                name
                preferredUsername
                domain
                avatar {
                  id
                  url
                }
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
            ... on Group {
              id
              preferredUsername
              domain
              name
              summary
              visibility
              openness
              physicalAddress {
                id
              }
              banner {
                id
              }
              avatar {
                id
              }
            }
          }
        }
      }
    }
  }
`;
