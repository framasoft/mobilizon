export enum LoginErrorCode {
  NEED_TO_LOGIN = "rouge",
}

export enum LoginError {
  USER_NOT_CONFIRMED = "User account not confirmed",
  USER_DOES_NOT_EXIST = "No user with this email was found",
  USER_EMAIL_PASSWORD_INVALID = "Impossible to authenticate, either your email or password are invalid.",
}
