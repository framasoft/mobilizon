import { IEvent, IParticipant } from '@/types/event.model';
import { IPerson } from '@/types/actor/person.model';

export enum ICurrentUserRole {
  USER = 'USER',
  MODERATOR = 'MODERATOR',
  ADMINISTRATOR = 'ADMINISTRATOR',
}

export interface ICurrentUser {
  id: number;
  email: string;
  isLoggedIn: boolean;
  role: ICurrentUserRole;
  participations: IParticipant[];
  defaultActor: IPerson;
  drafts: IEvent[];
}
