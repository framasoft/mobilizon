import gql from "graphql-tag";

export const SEARCH_EVENTS = gql`
  query SearchEvents(
    $location: String
    $radius: Float
    $tags: String
    $term: String
    $beginsOn: DateTime
    $endsOn: DateTime
  ) {
    searchEvents(
      location: $location
      radius: $radius
      tags: $tags
      term: $term
      beginsOn: $beginsOn
      endsOn: $endsOn
    ) {
      total
      elements {
        title
        uuid
        beginsOn
        picture {
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
  query SearchGroups($term: String, $location: String, $radius: Float) {
    searchGroups(term: $term, location: $location, radius: $radius) {
      total
      elements {
        avatar {
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
