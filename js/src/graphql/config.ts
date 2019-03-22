import gql from 'graphql-tag';

export const CONFIG = gql`
query {
  config {
    name,
    registrationsOpen
  }
}
`;
