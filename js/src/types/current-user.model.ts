import { IEvent, IParticipant } from '@/types/event.model';

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
  drafts: IEvent[];
}
