import gql from "graphql-tag";

export const ADDRESS_FRAGMENT = gql`
  fragment AdressFragment on Address {
    id
    description
    geom
    street
    locality
    postalCode
    region
    country
    type
    url
    originId
    timezone
  }
`;

export const ADDRESS = gql`
  query ($query: String!, $locale: String, $type: AddressSearchType) {
    searchAddress(query: $query, locale: $locale, type: $type) {
      ...AdressFragment
    }
  }
  ${ADDRESS_FRAGMENT}
`;

export const REVERSE_GEOCODE = gql`
  query ($latitude: Float!, $longitude: Float!, $zoom: Int, $locale: String) {
    reverseGeocode(
      latitude: $latitude
      longitude: $longitude
      zoom: $zoom
      locale: $locale
    ) {
      ...AdressFragment
    }
  }
  ${ADDRESS_FRAGMENT}
`;
