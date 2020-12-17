/* eslint-disable no-unused-vars */
export enum InstanceTermsType {
  DEFAULT = "DEFAULT",
  URL = "URL",
  CUSTOM = "CUSTOM",
}

export enum InstancePrivacyType {
  DEFAULT = "DEFAULT",
  URL = "URL",
  CUSTOM = "CUSTOM",
}

export enum ICurrentUserRole {
  USER = "USER",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
}

export enum INotificationPendingEnum {
  NONE = "NONE",
  DIRECT = "DIRECT",
  ONE_DAY = "ONE_DAY",
  ONE_HOUR = "ONE_HOUR",
}

export enum IAuthProvider {
  LDAP = "ldap",
  GOOGLE = "google",
  DISCORD = "discord",
  GITHUB = "github",
  KEYCLOAK = "keycloak",
  FACEBOOK = "facebook",
  GITLAB = "gitlab",
  TWITTER = "twitter",
}

export enum ErrorCode {
  UNKNOWN = "unknown",
  REGISTRATION_CLOSED = "registration_closed",
}

export enum CommentModeration {
  ALLOW_ALL = "ALLOW_ALL",
  MODERATED = "MODERATED",
  CLOSED = "CLOSED",
}

export enum EventStatus {
  TENTATIVE = "TENTATIVE",
  CONFIRMED = "CONFIRMED",
  CANCELLED = "CANCELLED",
}

export enum EventVisibility {
  PUBLIC = "PUBLIC",
  UNLISTED = "UNLISTED",
  RESTRICTED = "RESTRICTED",
  PRIVATE = "PRIVATE",
}

export enum EventJoinOptions {
  FREE = "FREE",
  RESTRICTED = "RESTRICTED",
  INVITE = "INVITE",
}

export enum EventVisibilityJoinOptions {
  PUBLIC = "PUBLIC",
  LINK = "LINK",
  LIMITED = "LIMITED",
}

export enum Category {
  BUSINESS = "business",
  CONFERENCE = "conference",
  BIRTHDAY = "birthday",
  DEMONSTRATION = "demonstration",
  MEETING = "meeting",
}

export enum LoginErrorCode {
  NEED_TO_LOGIN = "need_to_login",
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

export enum ParticipantRole {
  NOT_APPROVED = "NOT_APPROVED",
  NOT_CONFIRMED = "NOT_CONFIRMED",
  REJECTED = "REJECTED",
  PARTICIPANT = "PARTICIPANT",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
  CREATOR = "CREATOR",
}

export enum PostVisibility {
  PUBLIC = "PUBLIC",
  UNLISTED = "UNLISTED",
  RESTRICTED = "RESTRICTED",
  PRIVATE = "PRIVATE",
}

export enum ReportStatusEnum {
  OPEN = "OPEN",
  CLOSED = "CLOSED",
  RESOLVED = "RESOLVED",
}

export enum ActionLogAction {
  NOTE_CREATION = "NOTE_CREATION",
  NOTE_DELETION = "NOTE_DELETION",
  REPORT_UPDATE_CLOSED = "REPORT_UPDATE_CLOSED",
  REPORT_UPDATE_OPENED = "REPORT_UPDATE_OPENED",
  REPORT_UPDATE_RESOLVED = "REPORT_UPDATE_RESOLVED",
  EVENT_DELETION = "EVENT_DELETION",
  COMMENT_DELETION = "COMMENT_DELETION",
  ACTOR_SUSPENSION = "ACTOR_SUSPENSION",
  ACTOR_UNSUSPENSION = "ACTOR_UNSUSPENSION",
  USER_DELETION = "USER_DELETION",
}

export enum SearchTabs {
  EVENTS = 0,
  GROUPS = 1,
}

export enum ActorType {
  PERSON = "PERSON",
  APPLICATION = "APPLICATION",
  GROUP = "GROUP",
  ORGANISATION = "ORGANISATION",
  SERVICE = "SERVICE",
}

export enum MemberRole {
  NOT_APPROVED = "NOT_APPROVED",
  INVITED = "INVITED",
  MEMBER = "MEMBER",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
  CREATOR = "CREATOR",
  REJECTED = "REJECTED",
}

export enum Openness {
  INVITE_ONLY = "INVITE_ONLY",
  MODERATED = "MODERATED",
  OPEN = "OPEN",
}

export enum RoutingType {
  OPENSTREETMAP = "OPENSTREETMAP",
  GOOGLE_MAPS = "GOOGLE_MAPS",
}

export enum RoutingTransportationType {
  FOOT = "FOOT",
  BIKE = "BIKE",
  TRANSIT = "TRANSIT",
  CAR = "CAR",
}

export enum GroupVisibility {
  PUBLIC = "PUBLIC",
  UNLISTED = "UNLISTED",
  PRIVATE = "PRIVATE",
}
