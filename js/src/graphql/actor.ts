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
  createPerson(preferredUsername: $preferredUsername) {
    preferredUsername,
    name,
    avatarUrl
  }
}
`