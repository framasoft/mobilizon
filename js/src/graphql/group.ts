import gql from "graphql-tag";
import { DISCUSSION_BASIC_FIELDS_FRAGMENT } from "./discussion";
import { RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT } from "./resources";
import { POST_BASIC_FIELDS } from "./post";

export const LIST_GROUPS = gql`
  query {
    groups {
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

export const FETCH_GROUP = gql`
  query($name: String!) {
    group(preferredUsername: $name) {
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
  }
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

export const LEAVE_GROUP = gql`
  mutation LeaveGroup($groupId: ID!) {
    leaveGroup(groupId: $groupId) {
      id
    }
  }
`;
