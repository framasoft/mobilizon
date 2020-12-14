import gql from "graphql-tag";

const participantQuery = `
  role,
  id,
  actor {
    preferredUsername,
    avatar {
      id
      url
    },
    name,
    id,
    domain
  },
  event {
    id,
    uuid
  },
  metadata {
    cancellationToken,
    message
  },
  insertedAt
`;

const participantsQuery = `
  total,
  elements {
    ${participantQuery}
  }
`;

const physicalAddressQuery = `
  description,
  street,
  locality,
  postalCode,
  region,
  country,
  geom,
  type,
  id,
  originId
`;

const tagsQuery = `
  id,
  slug,
  title
`;

const optionsQuery = `
  maximumAttendeeCapacity,
  remainingAttendeeCapacity,
  showRemainingAttendeeCapacity,
  anonymousParticipation,
  showStartTime,
  showEndTime,
  offers {
    price,
    priceCurrency,
    url
  },
  participationConditions {
    title,
    content,
    url
  },
  attendees,
  program,
  commentModeration,
  showParticipationPrice,
  hideOrganizerWhenGroupEvent,
  __typename
`;

export const FETCH_EVENT = gql`
  query($uuid:UUID!) {
    event(uuid: $uuid) {
      id,
      uuid,
      url,
      local,
      title,
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
      draft,
      picture {
        id
        url
        name
      },
      publishAt,
      onlineAddress,
      phoneAddress,
      physicalAddress {
        ${physicalAddressQuery}
      }
      organizerActor {
        avatar {
          id
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
        summary
      },
      contacts {
        avatar {
          id
          url,
        }
        preferredUsername,
        name,
        summary,
        domain,
        url,
        id
      },
      attributedTo {
        avatar {
          id
          url,
        }
        preferredUsername,
        name,
        summary,
        domain,
        url,
        id
      },
      participantStats {
        going,
        notApproved,
        participant
      },
      tags {
        ${tagsQuery}
      },
      relatedEvents {
        id
        uuid,
        title,
        beginsOn,
        picture {
          id,
          url
        }
        physicalAddress {
          id
          description
        },
        organizerActor {
          id
          avatar {
            id
            url,
          },
          preferredUsername,
          domain,
          name,
        }
      },
      options {
        ${optionsQuery}
      }
    }
  }
`;

export const FETCH_EVENT_BASIC = gql`
  query($uuid: UUID!) {
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
  query {
    events {
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
          slug
          title
        }
      }
    }
  }
`;

export const CREATE_EVENT = gql`
  mutation createEvent(
    $organizerActorId: ID!,
    $attributedToId: ID,
    $title: String!,
    $description: String!,
    $beginsOn: DateTime!,
    $endsOn: DateTime,
    $status: EventStatus,
    $visibility: EventVisibility,
    $joinOptions: EventJoinOptions,
    $draft: Boolean,
    $tags: [String],
    $picture: MediaInput,
    $onlineAddress: String,
    $phoneAddress: String,
    $category: String,
    $physicalAddress: AddressInput,
    $options: EventOptionsInput,
    $contacts: [Contact]
  ) {
    createEvent(
      organizerActorId: $organizerActorId,
      attributedToId: $attributedToId,
      title: $title,
      description: $description,
      beginsOn: $beginsOn,
      endsOn: $endsOn,
      status: $status,
      visibility: $visibility,
      joinOptions: $joinOptions,
      draft: $draft,
      tags: $tags,
      picture: $picture,
      onlineAddress: $onlineAddress,
      phoneAddress: $phoneAddress,
      category: $category,
      physicalAddress: $physicalAddress
      options: $options,
      contacts: $contacts
    ) {
      id,
      uuid,
      title,
      url,
      local,
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
      draft,
      picture {
        id
        url
      },
      publishAt,
      category,
      onlineAddress,
      phoneAddress,
      physicalAddress {
        ${physicalAddressQuery}
      },
      attributedTo {
        id,
        domain,
        name,
        url,
        preferredUsername,
        avatar {
          id
          url
        }
      },
      organizerActor {
        avatar {
          id
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
      },
      contacts {
        avatar {
          id
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
      },
      participantStats {
        going,
        notApproved,
        participant
      },
      tags {
        ${tagsQuery}
      },
      options {
        ${optionsQuery}
      }
    }
  }
`;

export const EDIT_EVENT = gql`
  mutation updateEvent(
    $id: ID!,
    $title: String,
    $description: String,
    $beginsOn: DateTime,
    $endsOn: DateTime,
    $status: EventStatus,
    $visibility: EventVisibility,
    $joinOptions: EventJoinOptions,
    $draft: Boolean,
    $tags: [String],
    $picture: MediaInput,
    $onlineAddress: String,
    $phoneAddress: String,
    $organizerActorId: ID,
    $attributedToId: ID,
    $category: String,
    $physicalAddress: AddressInput,
    $options: EventOptionsInput,
    $contacts: [Contact]
  ) {
    updateEvent(
      eventId: $id,
      title: $title,
      description: $description,
      beginsOn: $beginsOn,
      endsOn: $endsOn,
      status: $status,
      visibility: $visibility,
      joinOptions: $joinOptions,
      draft: $draft,
      tags: $tags,
      picture: $picture,
      onlineAddress: $onlineAddress,
      phoneAddress: $phoneAddress,
      organizerActorId: $organizerActorId,
      attributedToId: $attributedToId,
      category: $category,
      physicalAddress: $physicalAddress
      options: $options,
      contacts: $contacts
    ) {
      id,
      uuid,
      title,
      url,
      local,
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
      draft,
      picture {
        id
        url
      },
      publishAt,
      category,
      onlineAddress,
      phoneAddress,
      physicalAddress {
        ${physicalAddressQuery}
      },
      attributedTo {
        id,
        domain,
        name,
        url,
        preferredUsername,
        avatar {
          id
          url
        }
      },
      contacts {
        avatar {
          id
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
      },
      organizerActor {
        avatar {
          id
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
      },
      participantStats {
        going,
        notApproved,
        participant
      },
      tags {
        ${tagsQuery}
      },
      options {
        ${optionsQuery}
      }
    }
  }
`;

export const JOIN_EVENT = gql`
  mutation JoinEvent($eventId: ID!, $actorId: ID!, $email: String, $message: String, $locale: String) {
    joinEvent(
      eventId: $eventId,
      actorId: $actorId,
      email: $email,
      message: $message,
      locale: $locale
    ) {
        ${participantQuery}
    }
  }
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
  query($uuid: UUID!, $page: Int, $limit: Int, $roles: String) {
    event(uuid: $uuid) {
      id,
      uuid,
      title,
      participants(page: $page, limit: $limit, roles: $roles) {
        ${participantsQuery}
      },
      participantStats {
        going,
        notApproved,
        rejected,
        participant
      }
    }
  }
`;

export const EVENT_PERSON_PARTICIPATION = gql`
  query($actorId: ID!, $eventId: ID!) {
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
  subscription($actorId: ID!, $eventId: ID!) {
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

export const GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED = gql`
  subscription($actorId: ID!) {
    groupMembershipChanged(personId: $actorId) {
      id
      memberships {
        total
        elements {
          id
          role
          parent {
            id
            preferredUsername
            name
            domain
            avatar {
              id
              url
            }
          }
          invitedBy {
            id
            preferredUsername
            name
          }
          insertedAt
          updatedAt
        }
      }
    }
  }
`;

export const FETCH_GROUP_EVENTS = gql`
  query(
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
