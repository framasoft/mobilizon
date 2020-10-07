import gql from "graphql-tag";

export const STATISTICS = gql`
  query {
    statistics {
      numberOfUsers
      numberOfEvents
      numberOfLocalEvents
      numberOfComments
      numberOfLocalComments
      numberOfGroups
      numberOfLocalGroups
      numberOfInstanceFollowings
      numberOfInstanceFollowers
    }
  }
`;
