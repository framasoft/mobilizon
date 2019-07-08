import { ICurrentUser } from '@/types/current-user.model';
import { IEvent } from '@/types/event.model';
import { Actor, IActor } from '@/types/actor/actor.model';

export interface IFeedToken {
  token: string;
  actor?: IPerson;
  user: ICurrentUser;
}

export interface IPerson extends IActor {
  feedTokens: IFeedToken[];
  goingToEvents: IEvent[];
}

export class Person extends Actor implements IPerson {
  feedTokens: IFeedToken[] = [];
  goingToEvents: IEvent[] = [];

  constructor(hash: IPerson | {} = {}) {
    super(hash);

    this.patch(hash);
  }

  patch (hash: any) {
    Object.assign(this, hash);
  }
}
