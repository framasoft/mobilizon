import type { IEvent } from "@/types/event.model";
import type { IPerson } from "@/types/actor/person.model";
import type { Paginate } from "./paginate";
import type { IParticipant } from "./participant.model";
import { ICurrentUserRole, INotificationPendingEnum } from "./enums";

export interface ICurrentUser {
  id: string;
  email: string;
  isLoggedIn: boolean;
  role: ICurrentUserRole;
  defaultActor?: IPerson;
}

export interface IUserPreferredLocation {
  range?: number;
  name?: string;
  geohash?: string;
}

export interface IUserSettings {
  timezone?: string;
  notificationOnDay?: boolean;
  notificationEachWeek?: boolean;
  notificationBeforeEvent?: boolean;
  notificationPendingParticipation?: INotificationPendingEnum;
  notificationPendingMembership?: INotificationPendingEnum;
  location?: IUserPreferredLocation;
}

export interface IUser extends ICurrentUser {
  confirmedAt: Date;
  confirmationSendAt: Date;
  actors: IPerson[];
  disabled: boolean;
  participations: Paginate<IParticipant>;
  mediaSize: number;
  drafts: IEvent[];
  settings: IUserSettings;
  locale: string;
  provider?: string;
  lastSignInAt: string;
  lastSignInIp: string;
  currentSignInIp: string;
  currentSignInAt: string;
}
