import gql from 'graphql-tag';

export const ADDRESS = gql`
    query($query:String!) {
        searchAddress(
            query: $query
        ) {
            description,
            geom,
            floor,
            street,
            locality,
            postalCode,
            region,
            country
        }
    }
`;
