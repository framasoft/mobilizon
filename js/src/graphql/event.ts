import gql from 'graphql-tag';

const participantQuery = `
  role,
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
  query($uuid:UUID!) {
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
      participants {
        ${participantQuery}
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
    $visibility: EventVisibility
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
    $visibility: EventVisibility
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
