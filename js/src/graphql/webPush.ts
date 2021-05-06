import gql from "graphql-tag";

export const REGISTER_PUSH_MUTATION = gql`
  mutation RegisterPush($endpoint: String!, $auth: String!, $p256dh: String!) {
    registerPush(endpoint: $endpoint, auth: $auth, p256dh: $p256dh)
  }
`;

export const UNREGISTER_PUSH_MUTATION = gql`
  mutation UnRegisterPush($endpoint: String!) {
    unregisterPush(endpoint: $endpoint)
  }
`;
