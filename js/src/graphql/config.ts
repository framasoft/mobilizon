import gql from 'graphql-tag';

export const CONFIG = gql`
query {
  config {
    name,
    description,
    registrationsOpen,
    countryCode,
    location {
      latitude,
      longitude,
      accuracyRadius
    }
  }
}
`;
