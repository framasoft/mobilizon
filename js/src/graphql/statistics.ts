import gql from "graphql-tag";

export const STATISTICS = gql`
  query {
    statistics {
      numberOfUsers
      numberOfEvents
      numberOfComments
    }
  }
`;
