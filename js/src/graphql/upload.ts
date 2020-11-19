import gql from "graphql-tag";

/* eslint-disable import/prefer-default-export */
export const UPLOAD_PICTURE = gql`
  mutation UploadPicture($file: Upload!, $alt: String, $name: String!) {
    uploadPicture(file: $file, alt: $alt, name: $name) {
      url
      id
    }
  }
`;
