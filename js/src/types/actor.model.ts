import { ICurrentUser } from '@/types/current-user.model';
import { IEvent } from '@/types/event.model';

export interface IActor {
  id?: string;
  url: string;
  name: string;
  domain: string|null;
  summary: string;
  preferredUsername: string;
  suspended: boolean;
  avatarUrl: string;
  bannerUrl: string;
}

export class Actor implements IActor {
  avatarUrl: string = '';
  bannerUrl: string = '';
  domain: string | null = null;
  name: string = '';
  preferredUsername: string = '';
  summary: string = '';
  suspended: boolean = false;
  url: string = '';
}

export interface IPerson extends IActor {
  feedTokens: IFeedToken[];
  goingToEvents: IEvent[];
}

export interface IGroup extends IActor {
  members: IMember[];
}

export class Person extends Actor implements IPerson {
  feedTokens: IFeedToken[] = [];
  goingToEvents: IEvent[] = [];
}

export interface IFeedToken {
  token: string;
  actor?: IPerson;
  user: ICurrentUser;
}

export enum MemberRole {
  PENDING,
  MEMBER,
  MODERATOR,
  ADMIN,
}

export interface IMember {
  role: MemberRole;
  parent: IGroup;
  actor: IActor;
}
