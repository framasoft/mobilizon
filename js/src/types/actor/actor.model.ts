import { IPicture } from "@/types/picture.model";

export enum ActorType {
  PERSON = "PERSON",
  APPLICATION = "APPLICATION",
  GROUP = "GROUP",
  ORGANISATION = "ORGANISATION",
  SERVICE = "SERVICE",
}

export interface IActor {
  id?: string;
  url: string;
  name: string;
  domain: string | null;
  summary: string;
  preferredUsername: string;
  suspended: boolean;
  avatar: IPicture | null;
  banner: IPicture | null;
  type: ActorType;
}

export class Actor implements IActor {
  id?: string;

  avatar: IPicture | null = null;

  banner: IPicture | null = null;

  domain: string | null = null;

  name = "";

  preferredUsername = "";

  summary = "";

  suspended = false;

  url = "";

  type: ActorType = ActorType.PERSON;

  constructor(hash: IActor | {} = {}) {
    Object.assign(this, hash);
  }

  get displayNameAndUsername(): string {
    return `${this.name} (${this.usernameWithDomain})`;
  }

  usernameWithDomain(): string {
    const domain = this.domain ? `@${this.domain}` : "";
    return `@${this.preferredUsername}${domain}`;
  }

  public displayName(): string {
    return this.name != null && this.name !== "" ? this.name : this.usernameWithDomain();
  }
}

export function usernameWithDomain(actor: IActor): string {
  if (actor.domain) {
    return `${actor.preferredUsername}@${actor.domain}`;
  }
  return actor.preferredUsername;
}
