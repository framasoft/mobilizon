import gql from 'graphql-tag';

export const SEARCH = gql`
query SearchEvents($searchText: String!) {
  search(search: $searchText) {
    ...on Event {
      title,
      uuid,
      __typename
    },
    ...on Actor {
      avatarUrl,
      domain,
      preferredUsername,
      __typename
    }
  }
}
`;
