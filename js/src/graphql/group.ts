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
          url
        }
        banner {
          url
        }
        organizedEvents {
          elements {
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
      url
    }
    banner {
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
  query($name: String!) {
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
  query($id: ID!) {
    getGroup(id: $id) {
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
    $creatorActorId: ID!
    $preferredUsername: String!
    $name: String!
    $summary: String
    $avatar: PictureInput
    $banner: PictureInput
  ) {
    createGroup(
      creatorActorId: $creatorActorId
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
        url
      }
      banner {
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
    $avatar: PictureInput
    $banner: PictureInput
    $visibility: GroupVisibility
    $physicalAddress: AddressInput
  ) {
    updateGroup(
      id: $id
      name: $name
      summary: $summary
      banner: $banner
      avatar: $avatar
      visibility: $visibility
      physicalAddress: $physicalAddress
    ) {
      id
      preferredUsername
      name
      summary
      avatar {
        url
      }
      banner {
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
