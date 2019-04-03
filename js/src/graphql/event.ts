import gql from 'graphql-tag';

const participantQuery = `
  role,
  actor {
    preferredUsername,
    avatarUrl,
    name,
    id
  }
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
      thumbnail,
      largeImage,
      publishAt,
      category,
      # online_address,
      # phone_address,
      physicalAddress {
        description,
        floor,
        street,
        locality,
        postal_code,
        region,
        country,
        geom
      }
      organizerActor {
        avatarUrl,
        preferredUsername,
        name,
      },
      # attributedTo {
      #     # avatarUrl,
      #     preferredUsername,
      #     name,
      # },
      participants {
        ${participantQuery}
      },
      tags {
        slug,
        title
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
      thumbnail,
      largeImage,
      publishAt,
      # online_address,
      # phone_address,
      physicalAddress {
        description,
        locality
      }
      organizerActor {
        avatarUrl,
        preferredUsername,
        name,
      },
      attributedTo {
        avatarUrl,
        preferredUsername,
        name,
      },
      category,
      participants {
        ${participantQuery}
      }
    }
  }
`;

export const CREATE_EVENT = gql`
  mutation CreateEvent(
  $title: String!,
  $description: String!,
  $organizerActorId: String!,
  $category: String!,
  $beginsOn: DateTime!
  ) {
    createEvent(
      title: $title,
      description: $description,
      beginsOn: $beginsOn,
      organizerActorId: $organizerActorId,
      category: $category
    ) {
      id,
      uuid,
      title
    }
  }
`;

export const EDIT_EVENT = gql`
  mutation EditEvent(
  $title: String!,
  $description: String!,
  $organizerActorId: Int!,
  $category: String!
  ) {
    EditEvent(title: $title, description: $description, organizerActorId: $organizerActorId, category: $category) {
      uuid
    }
  }
`;

export const JOIN_EVENT = gql`
  mutation JoinEvent($eventId: Int!, $actorId: Int!) {
    joinEvent(
      eventId: $eventId,
      actorId: $actorId
    ) {
        ${participantQuery}
    }
  }
`;

export const LEAVE_EVENT = gql`
  mutation LeaveEvent($eventId: Int!, $actorId: Int!) {
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
  mutation DeleteEvent($id: Int!, $actorId: Int!) {
    deleteEvent(
      id: $id,
      actorId: $actorId
    )
  }
`;
