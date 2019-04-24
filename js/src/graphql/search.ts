import gql from 'graphql-tag';

export const SEARCH_EVENTS = gql`
query SearchEvents($searchText: String!) {
  searchEvents(search: $searchText) {
    total,
    elements {
      title,
      uuid,
      beginsOn,
      tags {
        slug,
        title
      },
      __typename
    }
  }
}
`;

export const SEARCH_GROUPS = gql`
query SearchGroups($searchText: String!) {
  searchGroups(search: $searchText) {
    total,
    elements {
      avatarUrl,
      domain,
      preferredUsername,
      name,
      __typename
    }
  }
}
`;
