import gql from "graphql-tag";

export const AUTH_APPLICATION = gql`
  query AuthApplication($clientId: String!) {
    authApplication(clientId: $clientId) {
      clientId
      name
      website
    }
  }
`;

export const AUTORIZE_APPLICATION = gql`
  mutation AuthorizeApplication(
    $applicationClientId: String!
    $redirectURI: String!
    $state: String
    $scope: String
  ) {
    authorizeApplication(
      clientId: $applicationClientId
      redirectURI: $redirectURI
      state: $state
      scope: $scope
    ) {
      code
      state
    }
  }
`;

export const AUTH_AUTHORIZED_APPLICATIONS = gql`
  query AuthAuthorizedApplications {
    loggedUser {
      id
      authAuthorizedApplications {
        id
        application {
          name
          website
        }
        lastUsedAt
        insertedAt
      }
    }
  }
`;

export const REVOKED_AUTHORIZED_APPLICATION = gql`
  mutation RevokeApplicationToken($appTokenId: String!) {
    revokeApplicationToken(appTokenId: $appTokenId) {
      id
    }
  }
`;
