import { ICurrentUser } from "../current-user.model";
import { IEvent, IParticipant } from "../event.model";
import { Actor, IActor } from "./actor.model";
import { Paginate } from "../paginate";
import { IMember } from "./group.model";

export interface IFeedToken {
  token: string;
  actor?: IPerson;
  user: ICurrentUser;
}

export interface IPerson extends IActor {
  feedTokens: IFeedToken[];
  goingToEvents: IEvent[];
  participations: IParticipant[];
  memberships: Paginate<IMember>;
}

export class Person extends Actor implements IPerson {
  feedTokens: IFeedToken[] = [];

  goingToEvents: IEvent[] = [];

  participations: IParticipant[] = [];

  memberships!: Paginate<IMember>;

  constructor(hash: IPerson | {} = {}) {
    super(hash);

    this.patch(hash);
  }

  patch(hash: any) {
    Object.assign(this, hash);
  }
}
