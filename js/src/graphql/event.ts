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
  }
`;

const physicalAddressQuery = `
  description,
  floor,
  street,
  locality,
  postalCode,
  region,
  country,
  geom
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
`;

export const FETCH_EVENT = gql`
  query($uuid:UUID!, $roles: String) {
    event(uuid: $uuid) {
      id,
      uuid,
      url,
      local,
      title,
      slug,
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
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
      participants (roles: $roles) {
        ${participantQuery}
      },
      participantStats {
        approved,
        unapproved
      },
      tags {
        ${tagsQuery}
      },
      relatedEvents {
        uuid,
        title,
        beginsOn,
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
        description,
        locality
      }
      organizerActor {
        avatar {
          url
        },
        preferredUsername,
        name,
      },
      attributedTo {
        avatar {
          url
        },
        preferredUsername,
        name,
      },
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
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
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
      description,
      beginsOn,
      endsOn,
      status,
      visibility,
      joinOptions,
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

export const ACCEPT_PARTICIPANT = gql`
  mutation AcceptParticipant($id: ID!, $moderatorActorId: ID!) {
    acceptParticipation(id: $id, moderatorActorId: $moderatorActorId) {
      role,
      id
    }
  }
`;

export const REJECT_PARTICIPANT = gql`
  mutation RejectParticipant($id: ID!, $moderatorActorId: ID!) {
    rejectParticipation(id: $id, moderatorActorId: $moderatorActorId) {
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
  query($uuid: UUID!, $page: Int, $limit: Int, $roles: String) {
    event(uuid: $uuid) {
      participants(page: $page, limit: $limit, roles: $roles) {
        ${participantQuery}
      },
      participantStats {
        approved,
        unapproved
      }
    }
  }
`;
