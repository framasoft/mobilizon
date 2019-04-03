import gql from 'graphql-tag';

export const SEARCH = gql`
query SearchEvents($searchText: String!) {
  search(search: $searchText) {
    ...on Event {
      title,
      uuid,
      beginsOn,
      __typename
    },
    ...on Actor {
      avatarUrl,
      domain,
      preferredUsername,
      name,
      __typename
    }
  }
}
`;
