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
      },
      publishAt,
      category,
      # online_address,
      # phone_address,
      physicalAddress {
        description,
        floor,
        street,
        locality,
        postalCode,
        region,
        country,
        geom
      }
      organizerActor {
        avatar {
          url
        },
        preferredUsername,
        domain,
        name,
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
        slug,
        title
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
  mutation CreateEvent(
  $title: String!,
  $description: String!,
  $organizerActorId: ID!,
  $category: String!,
  $beginsOn: DateTime!,
  $picture_file: Upload,
  $picture_name: String,
  ) {
    createEvent(
      title: $title,
      description: $description,
      beginsOn: $beginsOn,
      organizerActorId: $organizerActorId,
      category: $category,
      picture: {
          picture: {
              file: $picture_file,
              name: $picture_name,
          }
      }
    ) {
      id,
      uuid,
      title,
      picture {
        url
      }
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
