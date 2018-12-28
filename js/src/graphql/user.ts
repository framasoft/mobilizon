import gql from 'graphql-tag';

export const CREATE_USER = gql`
mutation CreateUser($email: String!, $username: String!, $password: String!) {
  createUser(email: $email, username: $username, password: $password) {
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
    }
  }
}
`;
