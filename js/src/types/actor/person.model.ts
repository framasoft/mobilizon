import type { ICurrentUser } from "../current-user.model";
import type { IEvent } from "../event.model";
import { Actor } from "./actor.model";
import type { IActor } from "./actor.model";
import type { Paginate } from "../paginate";
import type { IParticipant } from "../participant.model";
import type { IMember } from "./member.model";
import type { IFeedToken } from "../feedtoken.model";
import { IFollower } from "./follower.model";

export interface IPerson extends IActor {
  feedTokens: IFeedToken[];
  goingToEvents: IEvent[];
  participations: Paginate<IParticipant>;
  memberships: Paginate<IMember>;
  follows: Paginate<IFollower>;
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
  follows!: Paginate<IFollower>;

  patch(hash: IPerson | Record<string, unknown>): void {
    Object.assign(this, hash);
  }
}
