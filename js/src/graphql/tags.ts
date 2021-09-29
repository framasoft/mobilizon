import gql from "graphql-tag";

export const TAG_FRAGMENT = gql`
  fragment TagFragment on Tag {
    id
    slug
    title
  }
`;

export const TAGS = gql`
  query Tags {
    tags {
      related {
        ...TagFragment
      }
      ...TagFragment
    }
  }
  ${TAG_FRAGMENT}
`;

export const FILTER_TAGS = gql`
  query FilterTags($filter: String) {
    tags(filter: $filter) {
      ...TagFragment
    }
  }
  ${TAG_FRAGMENT}
`;
