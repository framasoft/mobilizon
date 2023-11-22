import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";
import {
  PARTICIPANTS_QUERY_FRAGMENT,
  PARTICIPANT_QUERY_FRAGMENT,
} from "./participant";
import { TAG_FRAGMENT } from "./tags";
import { CONVERSATIONS_QUERY_FRAGMENT } from "./conversations";

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
    externalParticipationUrl
    draft
    language
    category
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
      ...ActorFragment
    }
    contacts {
      ...ActorFragment
    }
    attributedTo {
      ...ActorFragment
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
      endsOn
      status
      language
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
        ...AdressFragment
      }
      organizerActor {
        ...ActorFragment
      }
      attributedTo {
        ...ActorFragment
      }
      options {
        ...EventOptions
      }
      tags {
        ...TagFragment
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
  ${ACTOR_FRAGMENT}
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
  query FetchEventBasic($uuid: UUID!) {
    event(uuid: $uuid) {
      id
      uuid
      joinOptions
      externalParticipationUrl
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
  query FetchEvents(
    $orderBy: EventOrderBy
    $direction: SortDirection
    $page: Int
    $limit: Int
  ) {
    events(
      orderBy: $orderBy
      direction: $direction
      page: $page
      limit: $limit
    ) {
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
        language
        picture {
          id
          url
        }
        publishAt
        physicalAddress {
          ...AdressFragment
        }
        organizerActor {
          ...ActorFragment
        }
        attributedTo {
          ...ActorFragment
        }
        category
        tags {
          ...TagFragment
        }
        options {
          ...EventOptions
        }
      }
    }
  }
  ${ADDRESS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
  ${ACTOR_FRAGMENT}
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
    $externalParticipationUrl: String
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
    $onlineAddress: String
    $phoneAddress: String
    $category: EventCategory
    $physicalAddress: AddressInput
    $options: EventOptionsInput
    $contacts: [Contact]
    $metadata: [EventMetadataInput]
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
      externalParticipationUrl: $externalParticipationUrl
      draft: $draft
      tags: $tags
      picture: $picture
      onlineAddress: $onlineAddress
      phoneAddress: $phoneAddress
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
    $externalParticipationUrl: String
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
    $onlineAddress: String
    $phoneAddress: String
    $organizerActorId: ID
    $attributedToId: ID
    $category: EventCategory
    $physicalAddress: AddressInput
    $options: EventOptionsInput
    $contacts: [Contact]
    $metadata: [EventMetadataInput]
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
      externalParticipationUrl: $externalParticipationUrl
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
    $timezone: Timezone
  ) {
    joinEvent(
      eventId: $eventId
      actorId: $actorId
      email: $email
      message: $message
      locale: $locale
      timezone: $timezone
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
      organizerActor {
        ...ActorFragment
      }
      attributedTo {
        ...ActorFragment
      }
    }
  }
  ${PARTICIPANTS_QUERY_FRAGMENT}
  ${ACTOR_FRAGMENT}
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
    $order: EventOrderBy
    $orderDirection: SortDirection
    $organisedEventsPage: Int
    $organisedEventsLimit: Int
  ) {
    group(preferredUsername: $name) {
      organizedEvents(
        afterDatetime: $afterDateTime
        beforeDatetime: $beforeDateTime
        order: $order
        orderDirection: $orderDirection
        page: $organisedEventsPage
        limit: $organisedEventsLimit
      ) {
        elements {
          id
          uuid
          title
          beginsOn
          status
          draft
          options {
            ...EventOptions
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
          physicalAddress {
            ...AdressFragment
          }
          picture {
            url
            id
          }
        }
        total
      }
      ...ActorFragment
    }
  }
  ${EVENT_OPTIONS_FRAGMENT}
  ${ACTOR_FRAGMENT}
  ${ADDRESS_FRAGMENT}
`;

export const EXPORT_EVENT_PARTICIPATIONS = gql`
  mutation ExportEventParticipants(
    $eventId: ID!
    $format: ExportFormatEnum
    $roles: [ParticipantRoleEnum]
  ) {
    exportEventParticipants(eventId: $eventId, format: $format, roles: $roles) {
      path
      format
    }
  }
`;

export const EVENT_CONVERSATIONS = gql`
  query EventConversations($uuid: UUID!, $page: Int, $limit: Int) {
    event(uuid: $uuid) {
      id
      uuid
      title
      conversations(page: $page, limit: $limit) {
        ...ConversationsQuery
      }
    }
  }
  ${CONVERSATIONS_QUERY_FRAGMENT}
`;

export const USER_CONVERSATIONS = gql`
  query UserConversations($page: Int, $limit: Int) {
    loggedUser {
      id
      conversations(page: $page, limit: $limit) {
        ...ConversationsQuery
      }
    }
  }
  ${CONVERSATIONS_QUERY_FRAGMENT}
`;

export const PROFILE_CONVERSATIONS = gql`
  query ProfileConversations($page: Int, $limit: Int) {
    loggedPerson {
      id
      conversations(page: $page, limit: $limit) {
        ...ConversationsQuery
      }
    }
  }
  ${CONVERSATIONS_QUERY_FRAGMENT}
`;
