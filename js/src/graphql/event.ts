import gql from 'graphql-tag';

const participantQuery = `
  role,
  id,
  actor {
    preferredUsername,
    avatar {
      url
    },
    name,
    id
  },
  event {
    id
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
  id
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
  showParticipationPrice
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
      category,
      onlineAddress,
      phoneAddress,
      physicalAddress {
        ${physicalAddressQuery}
      }
      organizerActor {
        avatar {
          url
        },
        preferredUsername,
        domain,
        name,
        url,
        id,
      },
      # attributedTo {
      #     avatar {
      #      url,
      #     }
      #     preferredUsername,
      #     name,
      # },
      participantStats {
        going,
        notApproved,
        participant
      },
      tags {
        ${tagsQuery}
      },
      relatedEvents {
        uuid,
        title,
        beginsOn,
        picture {
          id,
          url
        }
        physicalAddress {
          description
        },
        organizerActor {
          avatar {
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

export const FETCH_EVENTS = gql`
  query {
    events {
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
      picture {
        id
        url
      },
      publishAt,
      # online_address,
      # phone_address,
      physicalAddress {
        id,
        description,
        locality
      },
      organizerActor {
        id,
        avatar {
          url
        },
        preferredUsername,
        name,
      },
#      attributedTo {
#        avatar {
#          url
#        },
#        preferredUsername,
#        name,
#      },
      category,
      participants {
        ${participantQuery}
      },
      tags {
        slug,
        title
      },
    }
  }
`;

export const CREATE_EVENT = gql`
  mutation createEvent(
    $organizerActorId: ID!,
    $title: String!,
    $description: String!,
    $beginsOn: DateTime!,
    $endsOn: DateTime,
    $status: EventStatus,
    $visibility: EventVisibility,
    $joinOptions: EventJoinOptions,
    $draft: Boolean,
    $tags: [String],
    $picture: PictureInput,
    $onlineAddress: String,
    $phoneAddress: String,
    $category: String,
    $physicalAddress: AddressInput,
    $options: EventOptionsInput,
  ) {
    createEvent(
      organizerActorId: $organizerActorId,
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
      organizerActor {
        avatar {
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
    $picture: PictureInput,
    $onlineAddress: String,
    $phoneAddress: String,
    $category: String,
    $physicalAddress: AddressInput,
    $options: EventOptionsInput,
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
      category: $category,
      physicalAddress: $physicalAddress
      options: $options,
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
      organizerActor {
        avatar {
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
  mutation JoinEvent($eventId: ID!, $actorId: ID!) {
    joinEvent(
      eventId: $eventId,
      actorId: $actorId
    ) {
        ${participantQuery}
    }
  }
`;

export const LEAVE_EVENT = gql`
  mutation LeaveEvent($eventId: ID!, $actorId: ID!) {
    leaveEvent(
      eventId: $eventId,
      actorId: $actorId
    ) {
      actor {
        id
      }
    }
  }
`;

export const UPDATE_PARTICIPANT = gql`
  mutation AcceptParticipant($id: ID!, $moderatorActorId: ID!, $role: ParticipantRoleEnum!) {
    updateParticipation(id: $id, moderatorActorId: $moderatorActorId, role: $role) {
      role,
      id
    }
  }
`;

export const DELETE_EVENT = gql`
  mutation DeleteEvent($eventId: ID!, $actorId: ID!) {
    deleteEvent(
      eventId: $eventId,
      actorId: $actorId
    ) {
        id
    }
  }
`;

export const PARTICIPANTS = gql`
  query($uuid: UUID!, $page: Int, $limit: Int, $roles: String, $actorId: ID!) {
    event(uuid: $uuid) {
      id,
      participants(page: $page, limit: $limit, roles: $roles, actorId: $actorId) {
        ${participantQuery}
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
      id,
      participations(eventId: $eventId) {
        id,
        role,
        actor {
          id
        },
        event {
          id
        }
      }
    }
  }
`;
