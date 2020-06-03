import gql from "graphql-tag";

const $addressFragment = `
id,
description,
geom,
street,
locality,
postalCode,
region,
country,
type,
url,
originId
`;

export const ADDRESS = gql`
    query($query:String!, $locale: String) {
        searchAddress(
            query: $query,
            locale: $locale
        ) {
            ${$addressFragment}
        }
    }
`;

export const REVERSE_GEOCODE = gql`
    query($latitude: Float!, $longitude: Float!, $zoom: Int, $locale: String) {
        reverseGeocode(latitude: $latitude, longitude: $longitude, zoom: $zoom, locale: $locale) {
            ${$addressFragment}
        }
    }
`;
