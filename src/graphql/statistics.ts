import gql from "graphql-tag";

export const STATISTICS = gql`
  query Statistics {
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

export const CATEGORY_STATISTICS = gql`
  query CategoryStatistics {
    categoryStatistics {
      key
      number
    }
  }
`;
