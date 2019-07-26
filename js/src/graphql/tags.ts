import gql from 'graphql-tag';

export const TAGS = gql`
query {
  tags {
    id,
    related {
        id,
        slug,
        title
    }
    slug,
    title
  }
}
`;
