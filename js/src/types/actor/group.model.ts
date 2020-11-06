import { Actor, ActorType, IActor } from "./actor.model";
import { Paginate } from "../paginate";
import { IResource } from "../resource";
import { ITodoList } from "../todos";
import { IEvent } from "../event.model";
import { IDiscussion } from "../discussions";
import { IPerson } from "./person.model";
import { IPost } from "../post.model";
import { IAddress, Address } from "../address.model";

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

export interface IMember {
  id?: string;
  role: MemberRole;
  parent: IGroup;
  actor: IActor;
  invitedBy?: IPerson;
  insertedAt: string;
  updatedAt: string;
}

export interface IGroup extends IActor {
  members: Paginate<IMember>;
  resources: Paginate<IResource>;
  todoLists: Paginate<ITodoList>;
  discussions: Paginate<IDiscussion>;
  organizedEvents: Paginate<IEvent>;
  physicalAddress: IAddress;
  openness: Openness;
}

export class Group extends Actor implements IGroup {
  members: Paginate<IMember> = { elements: [], total: 0 };

  resources: Paginate<IResource> = { elements: [], total: 0 };

  todoLists: Paginate<ITodoList> = { elements: [], total: 0 };

  discussions: Paginate<IDiscussion> = { elements: [], total: 0 };

  organizedEvents: Paginate<IEvent> = { elements: [], total: 0 };

  posts: Paginate<IPost> = { elements: [], total: 0 };

  constructor(hash: IGroup | Record<string, unknown> = {}) {
    super(hash);
    this.type = ActorType.GROUP;

    this.patch(hash);
  }

  openness: Openness = Openness.INVITE_ONLY;

  physicalAddress: IAddress = new Address();

  patch(hash: IGroup | Record<string, unknown>): void {
    Object.assign(this, hash);
  }
}
