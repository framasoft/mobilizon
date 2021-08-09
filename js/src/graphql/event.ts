import gql from "graphql-tag";
import { ADDRESS_FRAGMENT } from "./address";
import { TAG_FRAGMENT } from "./tags";

const PARTICIPANT_QUERY_FRAGMENT = gql`
  fragment ParticipantQuery on Participant {
    role
    id
    actor {
      preferredUsername
      avatar {
        id
        url
      }
      name
      id
      domain
    }
    event {
      id
      uuid
    }
    metadata {
      cancellationToken
      message
    }
    insertedAt
  }
`;

const PARTICIPANTS_QUERY_FRAGMENT = gql`
  fragment ParticipantsQuery on PaginatedParticipantList {
    total
    elements {
      ...ParticipantQuery
    }
  }
  ${PARTICIPANT_QUERY_FRAGMENT}
`;

const EVENT_OPTIONS_FRAGMENT = gql`
  fragment EventOptions on EventOptions {
    maximumAttendeeCapacity
    remainingAttendeeCapacity
    showRemainingAttendeeCapacity
    anonymousParticipation
    showStartTime
    showEndTime
    offers {
      price
      priceCurrency
      url
    }
    participationConditions {
      title
      content
      url
    }
    attendees
    program
    commentModeration
    showParticipationPrice
    hideOrganizerWhenGroupEvent
  }
`;

const FULL_EVENT_FRAGMENT = gql`
  fragment FullEvent on Event {
    id
    uuid
    url
    local
    title
    description
    beginsOn
    endsOn
    status
    visibility
    joinOptions
    draft
    picture {
      id
      url
      name
      metadata {
        width
        height
        blurhash
      }
    }
    publishAt
    onlineAddress
    phoneAddress
    physicalAddress {
      ...AdressFragment
    }
    organizerActor {
      avatar {
        id
        url
      }
      preferredUsername
      domain
      name
      url
      id
      summary
    }
    contacts {
      avatar {
        id
        url
      }
      preferredUsername
      name
      summary
      domain
      url
      id
    }
    attributedTo {
      avatar {
        id
        url
      }
      preferredUsername
      name
      summary
      domain
      url
      id
    }
    participantStats {
      going
      notApproved
      participant
    }
    tags {
      ...TagFragment
    }
    relatedEvents {
      id
      uuid
      title
      beginsOn
      picture {
        id
        url
        name
        metadata {
          width
          height
          blurhash
        }
      }
      physicalAddress {
        id
        description
      }
      organizerActor {
        id
        avatar {
          id
          url
        }
        preferredUsername
        domain
        name
      }
    }
    options {
      ...EventOptions
    }
    metadata {
      key
      title
      value
      type
    }
  }
  ${ADDRESS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
`;

export const FETCH_EVENT = gql`
  query FetchEvent($uuid: UUID!) {
    event(uuid: $uuid) {
      ...FullEvent
    }
  }
  ${FULL_EVENT_FRAGMENT}
`;

export const FETCH_EVENT_BASIC = gql`
  query ($uuid: UUID!) {
    event(uuid: $uuid) {
      id
      uuid
      joinOptions
      participantStats {
        going
        notApproved
        notConfirmed
        participant
      }
    }
  }
`;

export const FETCH_EVENTS = gql`
  query FetchEvents($orderBy: EventOrderBy, $direction: SortDirection) {
    events(orderBy: $orderBy, direction: $direction) {
      total
      elements {
        id
        uuid
        url
        local
        title
        description
        beginsOn
        endsOn
        status
        visibility
        insertedAt
        picture {
          id
          url
        }
        publishAt
        # online_address,
        # phone_address,
        physicalAddress {
          id
          description
          locality
        }
        organizerActor {
          id
          avatar {
            id
            url
          }
          preferredUsername
          domain
          name
        }
        #      attributedTo {
        #        avatar {
        #          id
        #          url
        #        },
        #        preferredUsername,
        #        name,
        #      },
        category
        tags {
          ...TagFragment
        }
      }
    }
  }
  ${TAG_FRAGMENT}
`;

export const CREATE_EVENT = gql`
  mutation createEvent(
    $organizerActorId: ID!
    $attributedToId: ID
    $title: String!
    $description: String!
    $beginsOn: DateTime!
    $endsOn: DateTime
    $status: EventStatus
    $visibility: EventVisibility
    $joinOptions: EventJoinOptions
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
    $onlineAddress: String
    $phoneAddress: String
    $category: String
    $physicalAddress: AddressInput
    $options: EventOptionsInput
    $contacts: [Contact]
  ) {
    createEvent(
      organizerActorId: $organizerActorId
      attributedToId: $attributedToId
      title: $title
      description: $description
      beginsOn: $beginsOn
      endsOn: $endsOn
      status: $status
      visibility: $visibility
      joinOptions: $joinOptions
      draft: $draft
      tags: $tags
      picture: $picture
      onlineAddress: $onlineAddress
      phoneAddress: $phoneAddress
      category: $category
      physicalAddress: $physicalAddress
      options: $options
      contacts: $contacts
    ) {
      ...FullEvent
    }
  }
  ${FULL_EVENT_FRAGMENT}
`;

export const EDIT_EVENT = gql`
  mutation updateEvent(
    $id: ID!
    $title: String
    $description: String
    $beginsOn: DateTime
    $endsOn: DateTime
    $status: EventStatus
    $visibility: EventVisibility
    $joinOptions: EventJoinOptions
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
    $onlineAddress: String
    $phoneAddress: String
    $organizerActorId: ID
    $attributedToId: ID
    $category: String
    $physicalAddress: AddressInput
    $options: EventOptionsInput
    $contacts: [Contact]
    $metadata: EventMetadataInput
  ) {
    updateEvent(
      eventId: $id
      title: $title
      description: $description
      beginsOn: $beginsOn
      endsOn: $endsOn
      status: $status
      visibility: $visibility
      joinOptions: $joinOptions
      draft: $draft
      tags: $tags
      picture: $picture
      onlineAddress: $onlineAddress
      phoneAddress: $phoneAddress
      organizerActorId: $organizerActorId
      attributedToId: $attributedToId
      category: $category
      physicalAddress: $physicalAddress
      options: $options
      contacts: $contacts
      metadata: $metadata
    ) {
      ...FullEvent
    }
  }
  ${FULL_EVENT_FRAGMENT}
`;

export const JOIN_EVENT = gql`
  mutation JoinEvent(
    $eventId: ID!
    $actorId: ID!
    $email: String
    $message: String
    $locale: String
  ) {
    joinEvent(
      eventId: $eventId
      actorId: $actorId
      email: $email
      message: $message
      locale: $locale
    ) {
      ...ParticipantQuery
    }
  }
  ${PARTICIPANT_QUERY_FRAGMENT}
`;

export const LEAVE_EVENT = gql`
  mutation LeaveEvent($eventId: ID!, $actorId: ID!, $token: String) {
    leaveEvent(eventId: $eventId, actorId: $actorId, token: $token) {
      actor {
        id
      }
    }
  }
`;

export const CONFIRM_PARTICIPATION = gql`
  mutation ConfirmParticipation($token: String!) {
    confirmParticipation(confirmationToken: $token) {
      actor {
        id
      }
      event {
        id
        uuid
        joinOptions
      }
      role
    }
  }
`;

export const UPDATE_PARTICIPANT = gql`
  mutation UpdateParticipant($id: ID!, $role: ParticipantRoleEnum!) {
    updateParticipation(id: $id, role: $role) {
      role
      id
    }
  }
`;

export const DELETE_EVENT = gql`
  mutation DeleteEvent($eventId: ID!) {
    deleteEvent(eventId: $eventId) {
      id
    }
  }
`;

export const PARTICIPANTS = gql`
  query Participants($uuid: UUID!, $page: Int, $limit: Int, $roles: String) {
    event(uuid: $uuid) {
      id
      uuid
      title
      participants(page: $page, limit: $limit, roles: $roles) {
        ...ParticipantsQuery
      }
      participantStats {
        going
        notApproved
        rejected
        participant
      }
    }
  }
  ${PARTICIPANTS_QUERY_FRAGMENT}
`;

export const EVENT_PERSON_PARTICIPATION = gql`
  query EventPersonParticipation($actorId: ID!, $eventId: ID!) {
    person(id: $actorId) {
      id
      participations(eventId: $eventId) {
        total
        elements {
          id
          role
          actor {
            id
          }
          event {
            id
          }
        }
      }
    }
  }
`;

export const EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED = gql`
  subscription EventPersonParticipationSubscriptionChanged(
    $actorId: ID!
    $eventId: ID!
  ) {
    eventPersonParticipationChanged(personId: $actorId) {
      id
      participations(eventId: $eventId) {
        total
        elements {
          id
          role
          actor {
            id
          }
          event {
            id
          }
        }
      }
    }
  }
`;

export const FETCH_GROUP_EVENTS = gql`
  query FetchGroupEvents(
    $name: String!
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $organisedEventsPage: Int
    $organisedEventslimit: Int
  ) {
    group(preferredUsername: $name) {
      id
      preferredUsername
      domain
      name
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
    }
  }
`;

export const CLOSE_EVENTS = gql`
  query CloseEvents($location: String, $radius: Float) {
    searchEvents(location: $location, radius: $radius, page: 1, limit: 10) {
      total
      elements {
        id
        title
        uuid
        beginsOn
        picture {
          id
          url
        }
        tags {
          slug
          title
        }
        __typename
      }
    }
  }
`;
