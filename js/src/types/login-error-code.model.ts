export enum LoginErrorCode {
  NEED_TO_LOGIN = "rouge",
}

export enum LoginError {
  USER_NOT_CONFIRMED = "User account not confirmed",
  USER_DOES_NOT_EXIST = "No user with this email was found",
  USER_EMAIL_PASSWORD_INVALID = "Impossible to authenticate, either your email or password are invalid.",
  LOGIN_PROVIDER_ERROR = "Error with Login Provider",
  LOGIN_PROVIDER_NOT_FOUND = "Login Provider not found",
  USER_DISABLED = "This user has been disabled",
}

export enum ResetError {
  USER_IMPOSSIBLE_TO_RESET = "This user can't reset their password",
}
