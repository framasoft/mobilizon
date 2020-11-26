import gql from "graphql-tag";

export const UPLOAD_MEDIA = gql`
  mutation UploadMedia($file: Upload!, $alt: String, $name: String!) {
    uploadMedia(file: $file, alt: $alt, name: $name) {
      url
      id
    }
  }
`;

export const REMOVE_MEDIA = gql`
  mutation RemoveMedia($id: ID!) {
    removeMedia(id: $id) {
      id
    }
  }
`;
