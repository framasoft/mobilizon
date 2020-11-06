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
  avatar?: IPicture | null;
  banner?: IPicture | null;
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

  constructor(hash: IActor | Record<any, unknown> = {}) {
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

export function usernameWithDomain(actor: IActor, force = false): string {
  if (actor.domain) {
    return `${actor.preferredUsername}@${actor.domain}`;
  }
  if (force) {
    return `${actor.preferredUsername}@${window.location.hostname}`;
  }
  return actor.preferredUsername;
}

export function displayNameAndUsername(actor: IActor): string {
  if (actor.name) {
    return `${actor.name} (@${usernameWithDomain(actor)})`;
  }
  return usernameWithDomain(actor);
}
