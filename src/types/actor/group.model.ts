import type { IActor } from "./actor.model";
import { Actor } from "./actor.model";
import type { Paginate } from "../paginate";
import type { IResource } from "../resource";
import type { IEvent } from "../event.model";
import type { IDiscussion } from "../discussions";
import type { IPost } from "../post.model";
import { Address, type IAddress } from "../address.model";
import { ActorType, GroupVisibility, Openness } from "../enums";
import type { IMember } from "./member.model";
import type { ITodoList } from "../todolist";
import { IActivity } from "../activity.model";
import { IFollower } from "./follower.model";

export interface IGroup extends IActor {
  members: Paginate<IMember>;
  resources: Paginate<IResource>;
  todoLists: Paginate<ITodoList>;
  discussions: Paginate<IDiscussion>;
  organizedEvents: Paginate<IEvent>;
  posts: Paginate<IPost>;
  physicalAddress: IAddress;
  openness: Openness;
  visibility: GroupVisibility;
  manuallyApprovesFollowers: boolean;
  activity: Paginate<IActivity>;
  followers: Paginate<IFollower>;
  membersCount?: number;
  followersCount?: number;
}

export class Group extends Actor implements IGroup {
  members: Paginate<IMember> = { elements: [], total: 0 };
  followers: Paginate<IFollower> = { elements: [], total: 0 };

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
  visibility: GroupVisibility = GroupVisibility.PUBLIC;
  activity: Paginate<IActivity> = { elements: [], total: 0 };

  openness: Openness = Openness.MODERATED;

  physicalAddress: IAddress = new Address();

  manuallyApprovesFollowers = false;

  patch(hash: IGroup | Record<string, unknown>): void {
    Object.assign(this, hash);
  }
}
