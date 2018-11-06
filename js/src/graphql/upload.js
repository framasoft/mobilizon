import gql from 'graphql-tag';

export const UPLOAD_PICTURE = gql`
    mutation {
        uploadPicture(file: "file") {
            url,
            url_thumbnail
        }
    }
`;
