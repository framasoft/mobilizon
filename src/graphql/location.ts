import gql from "graphql-tag";

export const CURRENT_USER_LOCATION_CLIENT = gql`
  query currentUserLocation {
    currentUserLocation @client {
      lat
      lon
      accuracy
      isIPLocation
      name
      picture
    }
  }
`;

export const UPDATE_CURRENT_USER_LOCATION_CLIENT = gql`
  mutation UpdateCurrentUserLocation(
    $lat: Float
    $lon: Float
    $accuracy: Int
    $isIPLocation: Boolean
    $name: String
    $picture: pictureInfoElement
  ) {
    updateCurrentUserLocation(
      lat: $lat
      lon: $lon
      accuracy: $accuracy
      isIPLocation: $isIPLocation
      name: $name
      picture: $picture
    ) @client
  }
`;
