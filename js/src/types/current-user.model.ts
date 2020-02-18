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

export interface IUserSettings {
  timezone: string;
  notificationOnDay: string;
  notificationEachWeek: string;
  notificationBeforeEvent: string;
}
