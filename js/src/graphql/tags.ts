import gql from "graphql-tag";

export const TAG_FRAGMENT = gql`
  fragment TagFragment on Tag {
    id
    slug
    title
  }
`;

export const TAGS = gql`
  query {
    tags {
      id
      related {
        id
        slug
        title
      }
      slug
      title
    }
  }
`;
