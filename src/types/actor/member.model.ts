import type { IActor, IGroup, IPerson } from ".";
import { MemberRole } from "../enums";

export interface IMember {
  id?: string;
  role: MemberRole;
  parent: IGroup;
  actor: IActor;
  invitedBy?: IPerson;
  insertedAt: string;
  updatedAt: string;
}
