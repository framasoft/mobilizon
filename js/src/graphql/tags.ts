import gql from "graphql-tag";

/* eslint-disable import/prefer-default-export */
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
