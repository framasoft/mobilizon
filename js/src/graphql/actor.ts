import gql from 'graphql-tag';

export const FETCH_PERSON = gql`
query($name:String!) {
  person(preferredUsername: $name) {
    id,
    url,
    name,
    domain,
    summary,
    preferredUsername,
    suspended,
    avatar {
      name,
      url
    },
    banner {
      url
    },
    feedTokens {
        token
    },
    organizedEvents {
        uuid,
        title,
        beginsOn
    },
  }
}
`;

export const LOGGED_PERSON = gql`
query {
  loggedPerson {
    id,
    avatar {
      url
    },
    preferredUsername,
  }
}`;

export const LOGGED_PERSON_WITH_GOING_TO_EVENTS = gql`
query {
  loggedPerson {
    id,
    avatar {
        url
    },
    preferredUsername,
    goingToEvents {
        uuid,
        title,
        beginsOn,
        participants {
            actor {
                id,
                preferredUsername
            }
        }
    },
  }
}`;

export const IDENTITIES = gql`
query {
  identities {
    id,
    avatar {
        url
    },
    preferredUsername,
    name
  }
}`;

export const CREATE_PERSON = gql`
mutation CreatePerson($preferredUsername: String!, $name: String!, $summary: String, $avatar: PictureInput) {
  createPerson(
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary,
      avatar: $avatar
    ) {
    id,
    preferredUsername,
    name,
    summary,
    avatar {
      url
    }
  }
}
`;

export const UPDATE_PERSON = gql`
  mutation UpdatePerson($preferredUsername: String!, $name: String, $summary: String, $avatar: PictureInput) {
    updatePerson(
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary,
      avatar: $avatar
    ) {
      id,
      preferredUsername,
      name,
      summary,
      avatar {
        url
      },
    }
  }
`;

export const DELETE_PERSON = gql`
  mutation DeletePerson($preferredUsername: String!) {
    deletePerson(preferredUsername: $preferredUsername) {
      preferredUsername,
    }
  }
`;

/**
 * This one is used only to register the first account. Prefer CREATE_PERSON when creating another identity
 */
export const REGISTER_PERSON = gql`
mutation ($preferredUsername: String!, $name: String!, $summary: String!, $email: String!) {
  registerPerson(
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary,
      email: $email
    ) {
    preferredUsername,
    name,
    summary,
    avatar {
      url
    },
  }
}
`;

export const FETCH_GROUP = gql`
query($name:String!) {
  group(preferredUsername: $name) {
    id,
    url,
    name,
    domain,
    summary,
    preferredUsername,
    suspended,
    avatar {
      url
    },
    banner {
      url
    }
    organizedEvents {
        uuid,
        title,
        beginsOn
    },
    members {
        role,
        actor {
            id,
            name,
            domain,
            preferredUsername
        }
    }
  }
}
`;

export const CREATE_GROUP = gql`
  mutation CreateGroup(
    $creatorActorId: ID!,
    $preferredUsername: String!,
    $name: String!,
    $summary: String,
    $avatar: PictureInput,
    $banner: PictureInput
  ) {
    createGroup(
      creatorActorId: $creatorActorId,
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary,
      banner: $banner,
      avatar: $avatar
    ) {
      id,
      preferredUsername,
      name,
      summary,
      avatar {
        url
      },
      banner {
        url
      }
    }
  }
`;
