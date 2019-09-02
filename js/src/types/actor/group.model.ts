import { Actor, IActor } from '@/types/actor/actor.model';

export enum MemberRole {
  PENDING,
  MEMBER,
  MODERATOR,
  ADMIN,
}

export interface IGroup extends IActor {
  members: IMember[];
}

export interface IMember {
  role: MemberRole;
  parent: IGroup;
  actor: IActor;
}

export class Group extends Actor implements IGroup {
  members: IMember[] = [];

  constructor(hash: IGroup | {} = {}) {
    super(hash);

    this.patch(hash);
  }

  patch (hash: any) {
    Object.assign(this, hash);
  }
}
