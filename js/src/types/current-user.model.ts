import { IEvent, IParticipant } from "@/types/event.model";
import { IPerson } from "@/types/actor/person.model";
import { Paginate } from "./paginate";

export enum ICurrentUserRole {
  USER = "USER",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
}

export interface ICurrentUser {
  id: string;
  email: string;
  isLoggedIn: boolean;
  role: ICurrentUserRole;
  defaultActor?: IPerson;
}

export interface IUser extends ICurrentUser {
  confirmedAt: Date;
  confirmationSendAt: Date;
  actors: IPerson[];
  disabled: boolean;
  participations: Paginate<IParticipant>;
  drafts: IEvent[];
  settings: IUserSettings;
  locale: string;
  provider?: string;
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

export enum INotificationPendingParticipationEnum {
  NONE = "NONE",
  DIRECT = "DIRECT",
  ONE_DAY = "ONE_DAY",
  ONE_HOUR = "ONE_HOUR",
}

export interface IUserSettings {
  timezone: string;
  notificationOnDay: boolean;
  notificationEachWeek: boolean;
  notificationBeforeEvent: boolean;
  notificationPendingParticipation: INotificationPendingParticipationEnum;
}
