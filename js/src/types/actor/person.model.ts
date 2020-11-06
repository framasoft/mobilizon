import { ICurrentUser } from "../current-user.model";
import { IEvent } from "../event.model";
import { Actor, IActor } from "./actor.model";
import { Paginate } from "../paginate";
import { IMember } from "./group.model";
import { IParticipant } from "../participant.model";

export interface IFeedToken {
  token: string;
  actor?: IPerson;
  user: ICurrentUser;
}

export interface IPerson extends IActor {
  feedTokens: IFeedToken[];
  goingToEvents: IEvent[];
  participations: Paginate<IParticipant>;
  memberships: Paginate<IMember>;
  user?: ICurrentUser;
}

export class Person extends Actor implements IPerson {
  feedTokens: IFeedToken[] = [];

  goingToEvents: IEvent[] = [];

  participations!: Paginate<IParticipant>;

  memberships!: Paginate<IMember>;

  user!: ICurrentUser;

  constructor(hash: IPerson | Record<string, unknown> = {}) {
    super(hash);

    this.patch(hash);
  }

  patch(hash: IPerson | Record<string, unknown>): void {
    Object.assign(this, hash);
  }
}
