import gql from "graphql-tag";

export const SEARCH_EVENTS = gql`
  query SearchEvents(
    $location: String
    $radius: Float
    $tags: String
    $term: String
    $beginsOn: DateTime
    $endsOn: DateTime
    $page: Int
    $limit: Int
  ) {
    searchEvents(
      location: $location
      radius: $radius
      tags: $tags
      term: $term
      beginsOn: $beginsOn
      endsOn: $endsOn
      page: $page
      limit: $limit
    ) {
      total
      elements {
        id
        title
        uuid
        beginsOn
        picture {
          id
          url
        }
        tags {
          slug
          title
        }
        __typename
      }
    }
  }
`;

export const SEARCH_GROUPS = gql`
  query SearchGroups(
    $term: String
    $location: String
    $radius: Float
    $page: Int
    $limit: Int
  ) {
    searchGroups(
      term: $term
      location: $location
      radius: $radius
      page: $page
      limit: $limit
    ) {
      total
      elements {
        id
        avatar {
          id
          url
        }
        domain
        preferredUsername
        name
        __typename
      }
    }
  }
`;

export const SEARCH_PERSONS = gql`
  query SearchPersons($searchText: String!, $page: Int, $limit: Int) {
    searchPersons(term: $searchText, page: $page, limit: $limit) {
      total
      elements {
        id
        avatar {
          id
          url
        }
        domain
        preferredUsername
        name
        __typename
      }
    }
  }
`;

export const INTERACT = gql`
  query Interact($uri: String!) {
    interact(uri: $uri) {
      ... on Event {
        id
        title
        uuid
        beginsOn
        picture {
          id
          url
        }
        tags {
          slug
          title
        }
        __typename
      }
      ... on Group {
        id
        avatar {
          id
          url
        }
        domain
        preferredUsername
        name
        __typename
      }
    }
  }
`;
