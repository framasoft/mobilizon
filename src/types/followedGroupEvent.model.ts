import { IEvent } from "./event.model";
import { IPerson, IGroup } from "./actor";
import { IUser } from "./current-user.model";

export interface IFollowedGroupEvent {
  profile: IPerson;
  group: IGroup;
  user: IUser;
  event: IEvent;
}
