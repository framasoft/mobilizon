import gql from 'graphql-tag';

export const ADDRESS = gql`
    query($query:String!) {
        searchAddress(
            query: $query
        ) {
            id,
            description,
            geom,
            floor,
            street,
            locality,
            postalCode,
            region,
            country,
            url,
            originId
        }
    }
`;
