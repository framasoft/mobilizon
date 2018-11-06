import gql from 'graphql-tag';

export const FETCH_CATEGORIES = gql`
query {
    categories {
        id,
        title,
        description,
        picture {
            url,
        },
   }
}
`;

export const CREATE_CATEGORY = gql`
    mutation createCategory($title: String!, $description: String!, $picture: Upload!) {
        createCategory(title: $title, description: $description, picture: $picture) {
            id,
            title,
            description,
            picture {
                url,
                url_thumbnail
            },
        },
    },

`;
