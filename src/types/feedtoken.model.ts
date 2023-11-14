import type { IPerson } from "./actor";
import type { ICurrentUser } from "./current-user.model";

export interface IFeedToken {
  token: string;
  actor?: IPerson;
  user: ICurrentUser;
}
