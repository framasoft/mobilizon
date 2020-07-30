import { Actor, ActorType, IActor } from "./actor.model";
import { Paginate } from "../paginate";
import { IResource } from "../resource";
import { ITodoList } from "../todos";
import { IEvent } from "../event.model";
import { IDiscussion } from "../discussions";
import { IPerson } from "./person.model";
import { IPost } from "../post.model";

export enum MemberRole {
  NOT_APPROVED = "NOT_APPROVED",
  INVITED = "INVITED",
  MEMBER = "MEMBER",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
  CREATOR = "CREATOR",
  REJECTED = "REJECTED",
}

export interface IGroup extends IActor {
  members: Paginate<IMember>;
  resources: Paginate<IResource>;
  todoLists: Paginate<ITodoList>;
  discussions: Paginate<IDiscussion>;
  organizedEvents: Paginate<IEvent>;
}

export interface IMember {
  id?: string;
  role: MemberRole;
  parent: IGroup;
  actor: IActor;
  invitedBy?: IPerson;
}

export class Group extends Actor implements IGroup {
  members: Paginate<IMember> = { elements: [], total: 0 };

  resources: Paginate<IResource> = { elements: [], total: 0 };

  todoLists: Paginate<ITodoList> = { elements: [], total: 0 };

  discussions: Paginate<IDiscussion> = { elements: [], total: 0 };

  organizedEvents: Paginate<IEvent> = { elements: [], total: 0 };

  posts: Paginate<IPost> = { elements: [], total: 0 };

  constructor(hash: IGroup | {} = {}) {
    super(hash);
    this.type = ActorType.GROUP;

    this.patch(hash);
  }

  patch(hash: any) {
    Object.assign(this, hash);
  }
}
