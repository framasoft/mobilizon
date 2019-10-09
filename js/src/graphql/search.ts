import gql from 'graphql-tag';

export const SEARCH_EVENTS = gql`
query SearchEvents($searchText: String!) {
  searchEvents(search: $searchText) {
    total,
    elements {
      title,
      uuid,
      beginsOn,
      picture {
        url,
      },
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
      avatar {
        url
      },
      domain,
      preferredUsername,
      name,
      __typename
    }
  }
}
`;

export const SEARCH_PERSONS = gql`
  query SearchPersons($searchText: String!) {
    searchPersons(search: $searchText) {
      total,
      elements {
        id,
        avatar {
          url
        },
        domain,
        preferredUsername,
        name,
        __typename
      }
    }
  }
`;
