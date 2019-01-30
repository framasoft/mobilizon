import gql from 'graphql-tag';

export const CREATE_USER = gql`
mutation CreateUser($email: String!, $password: String!) {
  createUser(email: $email, password: $password) {
    email,
    confirmationSentAt
  }
}
`;

export const VALIDATE_USER = gql`
mutation ValidateUser($token: String!) {
  validateUser(token: $token) {
    token,
    user {
      id,
      email,
      defaultActor {
        id
      }
    }
  }
}
`;

export const CURRENT_USER_CLIENT = gql`
query {
  currentUser @client {
    id,
    email
  }
}
`;

export const UPDATE_CURRENT_USER_CLIENT = gql`
mutation UpdateCurrentUser($id: Int!, $email: String!) {
  updateCurrentUser(id: $id, email: $email) @client
}
`;
