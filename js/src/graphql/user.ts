import gql from "graphql-tag";

export const CREATE_USER = gql`
  mutation CreateUser($email: String!, $password: String!, $locale: String) {
    createUser(email: $email, password: $password, locale: $locale) {
      email
      confirmationSentAt
    }
  }
`;

export const VALIDATE_USER = gql`
  mutation ValidateUser($token: String!) {
    validateUser(token: $token) {
      accessToken
      refreshToken
      user {
        id
        email
        defaultActor {
          id
          preferredUsername
          name
          avatar {
            id
            url
          }
        }
      }
    }
  }
`;

export const LOGGED_USER = gql`
  query {
    loggedUser {
      id
      email
      defaultActor {
        id
        preferredUsername
        name
        avatar {
          id
          url
        }
      }
      provider
    }
  }
`;

export const CHANGE_PASSWORD = gql`
  mutation ChangePassword($oldPassword: String!, $newPassword: String!) {
    changePassword(oldPassword: $oldPassword, newPassword: $newPassword) {
      id
    }
  }
`;

export const CHANGE_EMAIL = gql`
  mutation ChangeEmail($email: String!, $password: String!) {
    changeEmail(email: $email, password: $password) {
      id
    }
  }
`;

export const VALIDATE_EMAIL = gql`
  mutation ValidateEmail($token: String!) {
    validateEmail(token: $token) {
      id
    }
  }
`;

export const DELETE_ACCOUNT = gql`
  mutation DeleteAccount($password: String, $userId: ID) {
    deleteAccount(password: $password, userId: $userId) {
      id
    }
  }
`;

export const SUSPEND_USER = gql`
  mutation SuspendUser($userId: ID) {
    deleteAccount(userId: $userId) {
      id
    }
  }
`;

export const CURRENT_USER_CLIENT = gql`
  query {
    currentUser @client {
      id
      email
      isLoggedIn
      role
    }
  }
`;

export const UPDATE_CURRENT_USER_CLIENT = gql`
  mutation UpdateCurrentUser(
    $id: String!
    $email: String!
    $isLoggedIn: Boolean!
    $role: UserRole!
  ) {
    updateCurrentUser(
      id: $id
      email: $email
      isLoggedIn: $isLoggedIn
      role: $role
    ) @client
  }
`;

export const USER_SETTINGS_FRAGMENT = gql`
  fragment UserSettingFragment on UserSettings {
    timezone
    notificationOnDay
    notificationEachWeek
    notificationBeforeEvent
    notificationPendingParticipation
    notificationPendingMembership
    location {
      range
      geohash
      name
    }
  }
`;

export const USER_SETTINGS = gql`
  query UserSetting {
    loggedUser {
      id
      locale
      settings {
        ...UserSettingFragment
      }
    }
  }
  ${USER_SETTINGS_FRAGMENT}
`;

export const SET_USER_SETTINGS = gql`
  mutation SetUserSettings(
    $timezone: String
    $notificationOnDay: Boolean
    $notificationEachWeek: Boolean
    $notificationBeforeEvent: Boolean
    $notificationPendingParticipation: NotificationPendingEnum
    $notificationPendingMembership: NotificationPendingEnum
    $location: LocationInput
  ) {
    setUserSettings(
      timezone: $timezone
      notificationOnDay: $notificationOnDay
      notificationEachWeek: $notificationEachWeek
      notificationBeforeEvent: $notificationBeforeEvent
      notificationPendingParticipation: $notificationPendingParticipation
      notificationPendingMembership: $notificationPendingMembership
      location: $location
    ) {
      ...UserSettingFragment
    }
  }
  ${USER_SETTINGS_FRAGMENT}
`;

export const LIST_USERS = gql`
  query ListUsers($email: String, $page: Int, $limit: Int) {
    users(email: $email, page: $page, limit: $limit) {
      total
      elements {
        id
        email
        locale
        confirmedAt
        disabled
        actors {
          id
          preferredUsername
          avatar {
            id
            url
          }
          name
          summary
        }
        settings {
          timezone
        }
      }
    }
  }
`;

export const GET_USER = gql`
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      email
      confirmedAt
      confirmationSentAt
      lastSignInAt
      lastSignInIp
      currentSignInIp
      currentSignInAt
      locale
      disabled
      mediaSize
      defaultActor {
        id
      }
      actors {
        id
        preferredUsername
        name
        avatar {
          id
          url
        }
      }
      participations {
        total
      }
      role
    }
  }
`;

export const UPDATE_USER_LOCALE = gql`
  mutation UpdateUserLocale($locale: String!) {
    updateLocale(locale: $locale) {
      id
      locale
    }
  }
`;
