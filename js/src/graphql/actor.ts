import gql from 'graphql-tag';

export const FETCH_PERSON = gql`
query($name:String!) {
  person(preferredUsername: $name) {
    url,
    name,
    domain,
    summary,
    preferredUsername,
    suspended,
    avatarUrl,
    bannerUrl,
    organizedEvents {
        uuid,
        title
    },
  }
}
`;

export const LOGGED_PERSON = gql`
query {
  loggedPerson {
    id,
    avatarUrl,
    preferredUsername,
  }
}`;

export const IDENTITIES = gql`
query {
  identities {
    avatarUrl,
    preferredUsername,
    name
  }
}`;

export const CREATE_PERSON = gql`
mutation CreatePerson($preferredUsername: String!) {
  createPerson(
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary
    ) {
    preferredUsername,
    name,
    summary,
    avatarUrl
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
    avatarUrl,
  }
}
`;
