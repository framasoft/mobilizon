import { IEvent, IParticipant } from "@/types/event.model";
import { IPerson } from "@/types/actor/person.model";
import { Paginate } from "./paginate";

export enum ICurrentUserRole {
  USER = "USER",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
}

export interface ICurrentUser {
  id: number;
  email: string;
  isLoggedIn: boolean;
  role: ICurrentUserRole;
  participations: Paginate<IParticipant>;
  defaultActor: IPerson;
  drafts: IEvent[];
  settings: IUserSettings;
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
